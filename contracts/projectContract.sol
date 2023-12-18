// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProjectContract is Ownable {
    using SafeMath for uint256;

    struct Project {
        string name;
        address creator;
        string description;
        uint256 capitalNeeded;
        Investment investment;
        bool isApproved;
    }

    struct Investment {
        address[] investors;
        uint256[] investments;
    }

    mapping(address => Project) public projects;
    address[] public projectAddresses;

    event ProjectCreated(
        address indexed creator,
        string name,
        string description,
        uint256 capitalNeeded
    );
    event InvestmentMade(
        address indexed investor,
        address indexed project,
        uint256 amount
    );
    event FundsWithdrawn(address indexed project, uint256 amount);
    event ProfitsPaid(address indexed project, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {
        // No additional logic needed for ProjectContract constructor
    }

    modifier onlyPlatformOwnerOrProjectCreator(address _project) {
        require(
            _msgSender() == owner() || _msgSender() == projects[_project].creator,
            "Only the project creator or platform owner can call this function."
        );
        _;
    }

    function createProject(
        string memory _name,
        string memory _description,
        uint256 _capitalNeeded
    ) external returns (address) {
        require(bytes(_name).length > 0, "Project name must not be empty.");
        require(
            bytes(_description).length > 0,
            "Project description must not be empty."
        );
        require(
            _capitalNeeded > 0,
            "Capital needed must be greater than zero."
        );

        Project storage project = projects[_msgSender()];
        require(
            bytes(project.name).length == 0,
            "Project already exists for this creator."
        );

        project.name = _name;
        project.creator = _msgSender();
        project.description = _description;
        project.capitalNeeded = _capitalNeeded;
        project.isApproved = false;

        projectAddresses.push(_msgSender());

        emit ProjectCreated(_msgSender(), _name, _description, _capitalNeeded);

        return _msgSender();
    }

    function invest(address _project, uint256 _amount) external payable {
        require(
            bytes(projects[_project].name).length > 0,
            "Project does not exist."
        );
        require(_amount > 0, "Investment amount must be greater than zero");

        Project storage project = projects[_project];
        project.investment.investors.push(_msgSender());
        project.investment.investments.push(_amount);

        emit InvestmentMade(_msgSender(), _project, _amount);
    }

    function payoutProfits(address _project) external payable onlyPlatformOwnerOrProjectCreator(_project) {
        Project storage project = projects[_project];
        require(project.isApproved, "Project is not approved yet.");

        uint256 totalProfits = address(this).balance - project.capitalNeeded;

        require(totalProfits > 0, "No profits available to payout.");

        for (uint256 i = 0; i < project.investment.investors.length; i++) {
            address investor = project.investment.investors[i];
            uint256 investmentAmount = project.investment.investments[i];
            uint256 profit = (investmentAmount * totalProfits) / project.capitalNeeded;

            payable(investor).transfer(profit);

            emit ProfitsPaid(_project, profit);
        }
    }

    function withdrawFunds(address _project) external payable onlyPlatformOwnerOrProjectCreator(_project) {
        Project storage project = projects[_project];

        uint256 amountToWithdraw = project.capitalNeeded;

        require(amountToWithdraw > 0, "No funds available for withdrawal.");
        require(project.isApproved, "Project is not approved yet.");

        project.capitalNeeded = 0;

        if (_msgSender() == owner()) {
            payable(owner()).transfer(amountToWithdraw);
        } else {
            payable(project.creator).transfer(amountToWithdraw);
        }

        emit FundsWithdrawn(_project, amountToWithdraw);
    }

    function approveProject(address _project) external onlyOwner {
        require(
            bytes(projects[_project].name).length > 0,
            "Project does not exist."
        );

        Project storage project = projects[_project];
        require(!project.isApproved, "Project is already approved.");

        project.isApproved = true;
    }

    function getProjectDetails(address _project)
        external
        view
        returns (
            string memory name,
            address creator,
            string memory description,
            uint256 capitalNeeded,
            bool isApproved
        )
    {
        Project storage project = projects[_project];
        return (
            project.name,
            project.creator,
            project.description,
            project.capitalNeeded,
            project.isApproved
        );
    }

    function getInvestorCount(address _project)
        external
        view
        returns (uint256)
    {
        Project storage project = projects[_project];
        return project.investment.investors.length;
    }

    function getInvestmentAmount(address _project, address _investor)
        external
        view
        returns (uint256)
    {
        Project storage project = projects[_project];
        Investment storage investment = project.investment;
        for (uint256 i = 0; i < investment.investors.length; i++) {
            if (investment.investors[i] == _investor) {
                return investment.investments[i];
            }
        }
        return 0; // Return 0 if the investor is not found
    }

    function getAllProjects() external view returns (address[] memory) {
        return projectAddresses;
    }
}
