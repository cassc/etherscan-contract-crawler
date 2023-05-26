pragma solidity >0.6.1 <0.7.0;

import "./provableAPI_0.6.sol";

import "./LuckyManekiNFT.sol";
import "./LuckyRaffle.sol";

contract LuckyProvable  is usingProvable
{
    address public creator;
    LuckyManekiNFT public ctxManeki;
    LuckyRaffle public ctxRaffle;

    struct Request {
        uint256 index;
        function(uint256, uint256) external callback;
    }

    mapping(bytes32 => Request) private requests;

    event RandomRequest(bytes32 queryId);
    event RandomResponse(bytes32 queryId, uint256 randomNumber, bool success);

    constructor() public {
        creator = msg.sender;

        provable_setProof(proofType_Ledger);

    }

    function setupManekiRaffle(address maneki, address raffle) public payable {
        require(msg.sender == creator, "sender!=creator");
        ctxManeki = LuckyManekiNFT(payable(maneki));
        ctxRaffle = LuckyRaffle(payable(raffle));
    }

    function execReveal() public {
        require(msg.sender == creator, "sender!=creator");
        _randomRequest(0x00, ctxManeki.__execReveal);
    }

    function execRaffle(uint256 index) public {
        require(msg.sender == creator, "sender!=creator");
        require(index <= ctxRaffle.raffleIndex(), "index>range");
        _randomRequest(index, ctxRaffle.__execRaffle);
    }

    function _randomRequest(
        uint256 index,
        function(uint256, uint256) external callback
    ) private {

            bytes32 _queryId = provable_newRandomDSQuery(0, 4, 400000);
            requests[_queryId] = Request(index, callback);

        emit RandomRequest(_queryId);
    }

    function __callback(
        bytes32 _queryId,
        string memory _result,
        bytes memory _proof
    ) public  override  {

        require(msg.sender == provable_cbAddress(), "sender");
        if (
            provable_randomDS_proofVerify__returnCode(
                _queryId,
                _result,
                _proof
            ) != 0
        ) {
            emit RandomResponse(_queryId, 0xDEAD, false);
        } else {
            uint256 randomNumber = uint256(
                keccak256(abi.encodePacked(_result))
            );
            emit RandomResponse(_queryId, randomNumber, true);
            requests[_queryId].callback(requests[_queryId].index, randomNumber);
        }

    }

    function withdraw(address recipient, uint256 amt) external {
        require(msg.sender == creator);
        (bool success, ) = payable(recipient).call{value: amt}("");
        require(success, "ERROR");
    }

    receive() external payable {}
}