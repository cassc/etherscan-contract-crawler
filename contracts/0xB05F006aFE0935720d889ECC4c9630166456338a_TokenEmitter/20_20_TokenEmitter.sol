// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {LinearVRGDA} from "lib/VRGDAs/src/LinearVRGDA.sol";
import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {toDaysWadUnsafe} from "lib/solmate/src/utils/SignedWadMath.sol";
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { AccessControlEnumerable } from "lib/openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

import { NontransferableERC20 } from "./NontransferableERC20.sol";
import { ITokenEmitter } from "./ITokenEmitter.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenEmitter is LinearVRGDA, ITokenEmitter, AccessControlEnumerable, ReentrancyGuard {

    //TODO: make treasury editable. Remember to remove the old treasury from admin status and add the new one when changing it in the function.
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Log(string name, uint256 value);

    // Vars 
    address treasury;


    NontransferableERC20 public token;
    
    uint256 public immutable startTime = block.timestamp;

    mapping(address => bool) public contractIsApproved;

    // approved contracts, owner, and a token contract address 
    constructor(
        NontransferableERC20 _token, 
        address _treasury,
        address[] memory _approvedBuyerContracts,
        int256 _targetPrice,  // SCALED BY E18. Target price. This is somewhat arbitrary for governance emissions, since there is no "target price" for 1 governance share. 
        int256 _priceDecayPercent, // SCALED BY E18. Price decay percent. This indicates how aggressively you discount governance when sales are not occurring. 
        int256 _governancePerTimeUnit // SCALED BY E18. The number of tokens to target selling in 1 full unit of time. 
    ) LinearVRGDA(_targetPrice, _priceDecayPercent, _governancePerTimeUnit) {

        
        treasury = _treasury;

        for (uint i = 0; i < _approvedBuyerContracts.length; i++) {
            contractIsApproved[_approvedBuyerContracts[i]] = true;
        }

        token = _token;

        // TODO: remove this once we don't need to move so fast 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _mint(
        address _to, 
        uint _amount
    ) private {
        token.mint(_to, _amount);
    }

    function totalSupply() public view returns (uint) {
        // returns total supply of issued so far 
        return token.totalSupply();
    }

    function balanceOf(address _owner) public view returns (uint) {
        // returns balance of address 
        return token.balanceOf(_owner);
    }
 
    // takes a list of addresses and a list of payout percentages 
    function buyToken(
        address[] memory _addresses, 
        uint[] memory _percentages
    ) public payable nonReentrant returns (uint256)  {
        uint startSupply = totalSupply();

        // ensure the same number of addresses and percentages
        require(_addresses.length == _percentages.length, "Addresses and percentages must be the same length");

        // ensure the calling contract is approved
        require(contractIsApproved[msg.sender], "Buyer is not approved");

        uint totalTokens = getTokenAmount(msg.value);
        (bool success, ) = treasury.call{value: msg.value}("");
        require(success, "Transfer failed.");

        // calculates how much total governance to give 

        uint sum = 0;

        // calculates how much governance to give each address
        for (uint i = 0; i < _addresses.length; i++) {

            uint tokens = totalTokens * _percentages[i] / 100;
            // transfer governance to address
            _mint(_addresses[i], tokens);
            sum += _percentages[i];
        }

        require(sum == 100, "Percentages must add up to 100");
        return totalTokens;
    }

    // This returns a safe, underestimated amount of governance.
    function getTokenAmount(uint256 payment) public view returns (uint256) {
        uint256 initialEstimatedAmount = UNSAFE_getOverestimateTokenAmount(payment);
        uint256 overestimatedPrice = getTokenPrice(totalSupply() + initialEstimatedAmount);
        uint256 underestimatedAmount = payment / overestimatedPrice;
        return underestimatedAmount;
    }

    // This will return MORE GOVERNANCE than it should. Never reward the user with this; the DAO will get taken over. 
    function UNSAFE_getOverestimateTokenAmount(uint256 payment) public view returns (uint256) {
        uint256 initialPrice = getTokenPrice(totalSupply());
        uint256 initialEstimatedAmount = payment / initialPrice;
        return initialEstimatedAmount;
    }

    function getTokenPrice(uint256 currentTotalSupply) public view returns (uint256) {
        uint256 price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), currentTotalSupply);
        // TODO make test that price never hits zero
        return price;
    }

    function setApprovedBuyerContract(address _contract, bool approved) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractIsApproved[_contract] = approved;
    }

    function transferTokenAdmin(address _newOwner)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        token.transferAdmin(_newOwner);
    }

}