// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockDAI is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    uint8 private _decimals = 6;
    string private constant _tokenURI = "https://cryptologos.cc/logos/multi-collateral-dai-dai-logo.png";

    constructor() 
        ERC20("DAI", "DAI") 
        ERC20Permit("DAI")
        Ownable(msg.sender)
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function tokenURI() public pure returns (string memory) {
        return _tokenURI;
    }

    function configureMinter(address minter, uint256 minterAllowedAmount) external onlyOwner {
        _approve(address(this), minter, minterAllowedAmount);
    }

    function blacklist(address account) external onlyOwner {
        _approve(account, address(this), 0);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
