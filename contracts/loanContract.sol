// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LoanContract {
    using SafeMath for uint256;

    struct Loan {
        address lender;
        address borrower;
        uint256 loanAmount;
        uint256 interestRate;
        uint256 repaymentAmount;
        uint256 repaymentTerm;
        uint256 remainingAmount;
        bool isClosed;
    }

    IERC20 public token; // Use IERC20 for token handling
    Loan[] public loans;

    event LoanCreated(
        address indexed lender,
        address indexed borrower,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 repaymentAmount,
        uint256 repaymentTerm
    );
    event LoanRepaid(address indexed borrower, uint256 repaymentAmount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function createLoan(
        address _borrower,
        uint256 _loanAmount,
        uint256 _interestRate,
        uint256 _repaymentTerm
    ) external {
        require(_borrower != address(0), "Invalid borrower address.");
        require(_loanAmount > 0, "Loan amount must be greater than zero.");
        require(_interestRate > 0, "Interest rate must be greater than zero.");
        require(
            _repaymentTerm > 0,
            "Repayment term must be greater than zero."
        );

        uint256 repaymentAmount = (_loanAmount * (100 + _interestRate)) / 100;

        Loan memory newLoan = Loan({
            lender: msg.sender,
            borrower: _borrower,
            loanAmount: _loanAmount,
            interestRate: _interestRate,
            repaymentAmount: repaymentAmount,
            repaymentTerm: _repaymentTerm,
            remainingAmount: repaymentAmount,
            isClosed: false
        });

        loans.push(newLoan);

        emit LoanCreated(
            msg.sender,
            _borrower,
            _loanAmount,
            _interestRate,
            repaymentAmount,
            _repaymentTerm
        );
    }

    function repayLoan(uint256 _loanIndex) external {
        require(_loanIndex < loans.length, "Invalid loan index.");
        Loan storage loan = loans[_loanIndex];
        require(
            loan.borrower == msg.sender,
            "Only the borrower can repay the loan."
        );
        require(!loan.isClosed, "Loan is already closed.");
        require(
            token.transferFrom(msg.sender, address(this), loan.repaymentAmount),
            "Token transfer failed"
        );

        loan.remainingAmount = loan.remainingAmount.sub(loan.repaymentAmount);
        if (loan.remainingAmount == 0) {
            loan.isClosed = true;
        }

        emit LoanRepaid(msg.sender, loan.repaymentAmount);
    }

    function withdraw() external {
        uint256 balance = token.balanceOf(msg.sender);
        require(balance > 0, "No funds available for withdrawal.");

        require(token.transfer(msg.sender, balance), "Token transfer failed");
    }

    function getLenderBalance() external view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function isLoanClosed(uint256 loanIndex) external view returns (bool) {
        require(loanIndex < loans.length, "Invalid loan index.");
        return loans[loanIndex].isClosed;
    }

    function markLoanAsClosed(uint256 loanIndex) external {
        require(loanIndex < loans.length, "Invalid loan index.");
        require(!loans[loanIndex].isClosed, "Loan is already closed.");
        loans[loanIndex].isClosed = true;
    }
}
