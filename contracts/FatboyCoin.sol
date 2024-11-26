// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FatboyCoin is ERC20, Ownable {
    uint256 public charityRate = 200; // 2% for charity
    uint256 public ownerRate = 500; // 5% for owner

    uint256 private constant _totalSupply = 1e9 * 10 ** 18; // 1 billion tokens
    uint256 private constant _ownerSupply = 5e7 * 10 ** 18; // 50 million tokens
    uint256 private constant _charitySupply = 2e7 * 10 ** 18; // 20 million tokens
    uint256 private constant _liquiditySupply = 1e8 * 10 ** 18; // 100 million tokens

    address public charityWallet;

    uint256 public maxSellPercentage = 0.1 * 10 ** 18; // Max 0.1% per sell
    uint256 public sellCooldown = 1 minutes;

    mapping(address => uint256) public lastSellTime;
    mapping(address => uint256) public lastSellAmount;

    modifier antiDumping(address sender, uint256 amount) {
        require(
            amount <= (_totalSupply * maxSellPercentage) / 10 ** 18,
            "Sell exceeds max allowed amount"
        );
        uint256 timeSinceLastSell = block.timestamp - lastSellTime[sender];
        require(timeSinceLastSell >= sellCooldown, "Cooldown period not met");
        _;
    }

    // Constructor now takes the initial owner address to pass to Ownable
    constructor(
        address _charityWallet,
        address initialOwner
    ) ERC20("FatboyCoin", "FBC") Ownable(initialOwner) {
        _mint(msg.sender, _totalSupply);
        _mint(msg.sender, _ownerSupply);
        _mint(address(this), _liquiditySupply);
        charityWallet = _charityWallet;
    }

    mapping(address => bool) private _isExcludedFromFee;

    // Custom transfer with anti-dumping logic
    function customTransfer(
        address recipient,
        uint256 amount
    ) external antiDumping(msg.sender, amount) returns (bool) {
        address sender = msg.sender;

        uint256 charityAmount = (amount * charityRate) / 10000;
        uint256 ownerAmount = (amount * ownerRate) / 10000;
        uint256 totalFee = charityAmount + ownerAmount;
        uint256 amountAfterFee = amount - totalFee;

        // Directly call the super._transfer() function, without boolean assignments
        super._transfer(sender, charityWallet, charityAmount); // Charity transfer
        super._transfer(sender, msg.sender, ownerAmount); // Owner transfer
        super._transfer(sender, recipient, amountAfterFee); // Recipient transfer

        // Emit events for tracking (optional)
        emit CharityTransferred(charityWallet, charityAmount);
        emit OwnerTransferred(msg.sender, ownerAmount);

        return true;
    }

    // Function to withdraw Ether from the contract
    function withdrawEther(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner()).transfer(amount);
    }

    // Receive function to accept Ether (if needed)
    receive() external payable {}

    event CharityTransferred(address indexed charityWallet, uint256 amount);
    event OwnerTransferred(address indexed ownerWallet, uint256 amount);
}
