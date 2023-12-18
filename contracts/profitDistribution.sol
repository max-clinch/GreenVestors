// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProfitDistribution {
    using SafeMath for uint256;

    mapping(address => uint256) public investments;
    mapping(address => uint256) public profits;

    uint256 public totalInvestment;
    uint256 public totalProfits;

    uint256 public constant RATE_OF_RETURN = 10; // 10% fixed rate of return

    IERC20 public profitToken; // Use IERC20 for token handling

    event ProfitDistributed(address indexed investor, uint256 amount);

    constructor(address _tokenAddress) {
        profitToken = IERC20(_tokenAddress);
    }

    function distributeProfits() external {
        require(
            totalInvestment > 0,
            "No investments available for profit distribution."
        );

        for (uint256 i = 0; i < totalInvestment; i++) {
            address investor = msg.sender;
            uint256 investmentAmount = investments[investor];
            uint256 profit = (investmentAmount * RATE_OF_RETURN) / 100;

            profits[investor] = profits[investor].add(profit);
            totalProfits = totalProfits.add(profit);

            emit ProfitDistributed(investor, profit);
        }

        // Reset investments and total investment after profit distribution
        totalInvestment = 0;
        investments[msg.sender] = 0;
    }

    function withdrawProfits() external {
        require(profits[msg.sender] > 0, "No profits available to withdraw.");

        uint256 amountToWithdraw = profits[msg.sender];
        profits[msg.sender] = 0;
        totalProfits = totalProfits.sub(amountToWithdraw);

        require(profitToken.transfer(msg.sender, amountToWithdraw), "Token transfer failed");
    }

    function invest(uint256 _amount) external {
        require(_amount > 0, "Investment amount must be greater than zero.");

        require(profitToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        investments[msg.sender] = investments[msg.sender].add(_amount);
        totalInvestment = totalInvestment.add(_amount);
    }

    // Getter function to check if a user has profits available for withdrawal
    function hasProfitsToWithdraw(address investor) external view returns (bool) {
        return profits[investor] > 0;
    }

    // Getter function to check the available profits of a user
    function getAvailableProfits(address investor) external view returns (uint256) {
        return profits[investor];
    }
}
