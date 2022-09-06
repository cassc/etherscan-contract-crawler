// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { ChainlinkClient, Chainlink, LinkTokenInterface } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Wagies } from "./Wagies.sol";

contract TruflationIndicator is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    /* Errors */

    error NotAuthorized();

    /* Constants */

    address constant ORACLE_ID = 0xfE2dD37BC29f5fc4E0cad8F58F4Dbf4AddD5A59A;
    uint256 constant FEE = 0.01 ether;
    uint256 constant LOOK_BACK = 14;

    /* Storage */

    Wagies immutable _nft;

    string _jobID = "e5b99e0a2f79402998187b11f37c56a6";

    mapping(address => bool) _isUpdater;

    uint256 _requiredDifference = 0.5 ether;
    int256[] pastInflation;

    bool _enableSale = true;

    constructor(Wagies nft) {
        setPublicChainlinkToken();

        _nft = nft;
    }

    /* Modifiers */

    modifier onlyUpdater() {
        if (!(_isUpdater[msg.sender] || msg.sender == owner())) revert NotAuthorized();
        _;
    }

    /* Non-view functions */

    function fulfillResponse(bytes32 _requestId, bytes memory _response) public recordChainlinkFulfillment(_requestId) {
        int256 value = _toInt256(_response);
        _checkInflation(value);
        pastInflation.push(value);
    }

    /* View functions */

    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    function getRequiredDifference() public view returns (uint256) {
        return _requiredDifference;
    }

    /* onlyOwner functions */

    function requestUpdate() public onlyUpdater returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(bytes32(bytes(_jobID)), address(this), this.fulfillResponse.selector);

        req.add("service", "truflation/current");
        req.add("keypath", "yearOverYearInflation");
        req.add("abi", "int256");
        req.add("multiplier", "1000000000000000000");
        return sendChainlinkRequestTo(ORACLE_ID, req, FEE);
    }

    function withdrawLink(uint256 amount) public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        if (link.transfer(msg.sender, amount) == false) revert();
    }

    function changeRequiredDifference(uint256 requiredDifference) public onlyOwner {
        _requiredDifference = requiredDifference;
    }

    function changeJobID(string memory jobID) public onlyOwner {
        _jobID = jobID;
    }

    function setIsUpdater(address updater, bool value) public onlyOwner {
        _isUpdater[updater] = value;
    }

    function toggleEnableSale() external onlyOwner {
        _enableSale = !_enableSale;
    }

    /* Internal functions */

    function _checkInflation(int256 value) internal {
        int256[] storage pI = pastInflation;
        uint256 requiredDifference = _requiredDifference;

        unchecked {
            uint256 len = pI.length;
            if (len == 0 || _enableSale == false) return;

            for (uint256 i = len - _min(len, LOOK_BACK); i < len; i++) {
                uint256 difference = _abs(value - pI[i]);

                if (difference >= requiredDifference) {
                    _nft.truflationIndicatorEnable(difference);
                    return;
                }
            }
        }
    }

    function _toInt256(bytes memory _bytes) internal pure returns (int256 value) {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }
}