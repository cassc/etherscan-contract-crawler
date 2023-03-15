// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


contract FarmHorsesOwners is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;    

    
    uint256 public fee;    
    // bytes32 public jobId = "380a28e5e70249bc9a684310168a5b25"; // BSC TESTNET
    bytes32 public jobId = "b4a3889d3d7b40dd9bd7f1abc08781a2"; // BSC MAINNET

    struct RequestStatus {
        address user;
        uint256[] nfts;
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
    }

    mapping(bytes32 => RequestStatus) public s_requests;
    mapping(uint256 => address) public ids;
    mapping(address => uint256[]) public owners;

    event RequestOwner(address owner, uint256[] nfts);

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x404460C6A5EdE2D891e8297795264fDe62ADBB75); // BSC MAINNET
        setChainlinkOracle(0x4213B9302393810611a4904C13BdEb4BC9f6b867); // BSC MAINNET

        // setChainlinkToken(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06); // BSC TESTNET
        // setChainlinkOracle(0xcAa7137BbE561abF892A6a846d67e7986a0B7075); // BSC TESTNET


        fee = (1 * LINK_DIVISIBILITY) / 500; // 0,05 * 10**18 (Varies by network and job) // BSC MAINNET
        // fee = (1 * LINK_DIVISIBILITY) / 1000; // 0,001 * 10**18 (Varies by network and job) // BSC TESTNET
    }

    /**
     * Create a Chainlink request to retrieve response
     */
    function claimOwner() public {

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Send the user and get owners
        req.add("user", toAsciiString(msg.sender));        
        req.add("path", "owner");

        // Sends the request
        bytes32 _requestId = sendChainlinkRequest(req, fee);
        s_requests[_requestId] = RequestStatus({
            user: msg.sender,
            nfts: new uint256[](0),
            exists: true,
            fulfilled: false
        });
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(
        bytes32 _requestId,
        uint256[] memory _data
    ) public recordChainlinkFulfillment(_requestId) {
        address _user = s_requests[_requestId].user;

        for (uint i=0; i < _data.length; i++) {
            ids[_data[i]] = _user;
        }

        owners[_user] = _data;

        s_requests[_requestId].nfts = _data;
        s_requests[_requestId].fulfilled = true;

        emit RequestOwner(_user, _data);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }


    function getNfts(address _user) external view returns (uint256[] memory) {
        return owners[_user];
    }

    function setJobID(string memory _jobId) public onlyOwner {
        jobId =  stringToBytes32(_jobId);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }    

    function stringToBytes32(
        string memory source
    ) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}