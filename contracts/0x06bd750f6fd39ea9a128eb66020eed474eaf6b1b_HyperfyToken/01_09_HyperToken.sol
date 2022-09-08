// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VerifySig.sol";

contract HyperfyToken is
    ERC20,
    Pausable,
    Ownable,
    VerifySig,
    ReentrancyGuard
{
    uint256 public maxSupply = 100000000 * 10e18;

    uint256 bootstrapSupply = 10000000 * 10e18;
    uint256 bootstrapCounter;

    uint256 teamSupply;
    uint256 teamCounter;

    uint256 treasurySupply;
    uint256 treasuryCounter;

    uint256 seedSupply;
    uint256 seedCounter;

    uint256 incentiveSupply;
    uint256 incentiveCounter;

    uint256 reservedSupply;
    uint256 reservedCounter;

    bool distributionSet;

    mapping(address => uint256) public claimed;
    address public signer;

    constructor(address _signer) ERC20("Hyperfy Token", "HYPER") {
        setSigner(_signer);
    }

    function setDistribution(
        uint256 _teamSupply,
        uint256 _treasurySupply,
        uint256 _seedSupply,
        uint256 _incentiveSupply,
        uint256 _reservedSupply
    ) public onlyOwner {
        teamSupply = _teamSupply;
        treasurySupply = _treasurySupply;
        seedSupply = _seedSupply;
        incentiveSupply = _incentiveSupply;
        reservedSupply = _reservedSupply;
        distributionSet = true;
    }

    function setSigner(address _signer) public {
        signer = _signer;
    }

    function bootstrapClaim(
        address to,
        uint256 amount,
        bytes calldata signature
    ) public nonReentrant whenNotPaused {
        bool verified = verify(signer, to, amount, signature);
        uint256 claimable = amount - claimed[to];
        require(verified, "Signature cannot be verified");
        require(claimable > 0, "Not enough tokens to claim");
        require(
            bootstrapCounter + claimable <= bootstrapSupply,
            "Cannot exceed bootstrap supply"
        );
        if (verified) {
            _mint(to, amount);
            claimed[to] = amount;
            bootstrapCounter += claimable;
        }
    }

    function bootstrapMint(
        address[] calldata to,
        uint256[] calldata amount
    ) public onlyOwner {
        require(to.length == amount.length, "Invalid input");
        for (uint256 i = 0; i < to.length; i++) {
            require(
                bootstrapCounter + amount[i] <= bootstrapSupply,
                "Cannot exceed bootstrap supply"
            );
            _mint(to[i], amount[i]);
            bootstrapCounter += amount[i];
        }
    }

    function incentiveClaim(
        address to,
        uint256 amount,
        bytes calldata signature
    ) public nonReentrant whenNotPaused{
        bool verified = verify(signer, to, amount, signature);
        uint256 claimable = amount - claimed[to];
        require(verified, "Signature cannot be verified");
        require(claimable > 0, "Not enough tokens to claim");
        require(
            totalSupply() + claimable <= maxSupply,
            "Cannot exceed max supply"
        );
        require(
            incentiveCounter + claimable <= incentiveSupply,
            "Cannot exceed incentive supply"
        );
        if (verified) {
            _mint(to, amount);
            claimed[to] = amount;
            incentiveCounter += claimable;
        }
    }

    function devMint(address[] calldata to, uint256[] calldata amount, string calldata option) public onlyOwner {
        require(distributionSet, "Distribution has not been set");
        require(to.length == amount.length, "Invalid input");
        if(keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked("team"))) {
            for (uint256 i = 0; i < to.length; i++) {
                require(teamCounter + amount[i] <= teamSupply, "Cannot exceed team supply");
                _mint(to[i], amount[i]);
                teamCounter += amount[i];
            }
        } else if(keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked("treasury"))) {
            for (uint256 i = 0; i < to.length; i++) {
                require(treasuryCounter + amount[i] <= treasurySupply, "Cannot exceed treasury supply");
                _mint(to[i], amount[i]);
                treasuryCounter += amount[i];
            }
        } else if(keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked("seed"))) {
            for (uint256 i = 0; i < to.length; i++) {
                require(seedCounter + amount[i] <= seedSupply, "Cannot exceed seed supply");
                _mint(to[i], amount[i]);
                seedCounter += amount[i];
            }
        } else if(keccak256(abi.encodePacked(option)) == keccak256(abi.encodePacked("reserved"))) {
            for (uint256 i = 0; i < to.length; i++) {
                require(reservedCounter + amount[i] <= reservedSupply, "Cannot exceed reserved supply");
                _mint(to[i], amount[i]);
                reservedCounter += amount[i];
            }
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}