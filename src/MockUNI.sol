// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MockUNI is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    uint8 private constant _decimals = 18;
    string private constant _tokenURI = "https://cryptologos.cc/logos/uniswap-uni-logo.png";
    uint256 public constant maxSupply = 1_000_000_000 * 10**18;
    mapping(address => uint256) public lastMintTimestamp;
    uint256 public constant mintCooldown = 1 days;

    constructor() 
        ERC20("Uniswap", "UNI") 
        ERC20Permit("Uniswap")
        Ownable(msg.sender)
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        require(block.timestamp >= lastMintTimestamp[to] + mintCooldown, "Mint cooldown active");
        
        lastMintTimestamp[to] = block.timestamp;
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function tokenURI() public pure returns (string memory) {
        return _tokenURI;
    }

    function delegate(address delegatee) external {
        _approve(msg.sender, delegatee, balanceOf(msg.sender));
    }

    function getCurrentVotes(address account) external view returns (uint256) {
        return balanceOf(account);
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
