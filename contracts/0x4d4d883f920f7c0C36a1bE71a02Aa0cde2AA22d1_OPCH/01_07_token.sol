/*
Contract Security Audited by Certik : https://www.certik.com/projects/opticash
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ArbitraryTokenStorage {
    function unlockERC(IERC20 token, address to) external;
}

contract ERC20Storage is Ownable, ArbitraryTokenStorage {
    event UnlockERC(address to, uint256 amount);

    function unlockERC(IERC20 token, address to) external virtual override onlyOwner
    {
        require(address(token) != address(0),"Token Address cannot be address 0");
        require(address(to) != address(0),"Reciever Address cannot be address 0");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        require(token.transfer(to, balance), "Transfer failed");
        emit UnlockERC(to, balance);
    }
}

contract OPCH is ERC20Burnable, ERC20Storage {
    bool mintCalled = false;

    address public marketingAddress;
    address public teamAddress;
    address public strategicAddress;
    address public publicAddress;
    address public liquidityAddress;
    address public privateAddress;
    address public foundationAddress;
    address public advisersAddress;

    uint256 public constant MARKETING_LIMIT = 250 * (10**6) * 10**18;
    uint256 public constant TEAM_LIMIT = 60 * (10**6) * 10**18;
    uint256 public constant STRATEGIC_LIMIT = 100 * (10**6) * 10**18;
    uint256 public constant PUBLICSALE_LIMIT = 250 * (10**6) * 10**18;
    uint256 public constant LIQUIDITY_LIMIT = 100 * (10**6) * 10**18;
    uint256 public constant PRIVATESALE_LIMIT = 100 * (10**6) * 10**18;
    uint256 public constant FOUNDATION_LIMIT = 100 * (10**6) * 10**18;
    uint256 public constant ADVISERS_LIMIT = 40 * (10**6) * 10**18;

    event SetAllocation(uint256 supply);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function setAllocation(
        address marketingbucketAddress,
        address teambucketAddress,
        address strategicbucketAddress,
        address publicbucketAddress,
        address liquiditybucketAddress,
        address privatebucketAddress,
        address foundationbucketAddress,
        address advisersbucketAddress
    ) external onlyOwner {
        require(!mintCalled, "Allocation already done.");
        require(marketingbucketAddress != address(0),"Invalid marketing bucket address");
        require(teambucketAddress != address(0), "Invalid team bucket address");
        require(strategicbucketAddress != address(0),"Invalid strategic bucket address");
        require(publicbucketAddress != address(0), "Invalid public bucket address");
        require(liquiditybucketAddress != address(0),"Invalid liquidity bucket address");
        require(privatebucketAddress != address(0), "Invalid private bucket address");
        require(foundationbucketAddress != address(0),"Invalid foundation bucket address");
        require(advisersbucketAddress != address(0),"Invalid advisers bucket address");

        marketingAddress = marketingbucketAddress;
        teamAddress = teambucketAddress;
        strategicAddress = strategicbucketAddress;
        publicAddress = publicbucketAddress;
        liquidityAddress = liquiditybucketAddress;
        privateAddress = privatebucketAddress;
        foundationAddress = foundationbucketAddress;
        advisersAddress = advisersbucketAddress;

        _mint(marketingAddress, MARKETING_LIMIT);
        _mint(teamAddress, TEAM_LIMIT);
        _mint(strategicAddress, STRATEGIC_LIMIT);
        _mint(publicAddress, PUBLICSALE_LIMIT);
        _mint(liquidityAddress, LIQUIDITY_LIMIT);
        _mint(privateAddress, PRIVATESALE_LIMIT);
        _mint(advisersAddress, ADVISERS_LIMIT);
        _mint(foundationAddress, FOUNDATION_LIMIT);

        mintCalled = true;
        emit SetAllocation(totalSupply());
    }
}