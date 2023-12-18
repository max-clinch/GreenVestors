// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./loanContract.sol";
import "./profitDistribution.sol";
import "./projectContract.sol";

contract CombinedContract is LoanContract, ProfitDistribution, ProjectContract {
    constructor(address initialOwner) 
        LoanContract(initialOwner) 
        ProfitDistribution(initialOwner) 
        ProjectContract(initialOwner) 
    {
        // Additional initialization logic for the combined contract, if needed
    }
}