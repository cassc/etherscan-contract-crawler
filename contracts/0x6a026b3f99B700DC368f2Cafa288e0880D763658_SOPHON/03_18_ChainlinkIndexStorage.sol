// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;
import "./chainlink/VRFConsumerBase.sol";
import  "./openzeppelin/access/Ownable.sol";

abstract contract RandomNumberConsumer is VRFConsumerBase, Ownable{
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    

    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
    }}



contract ChainlinkRandomNumberConsumer is RandomNumberConsumer {

    mapping(uint256 => uint256[1111]) internal indexMapping;
    uint256[] internal expandedValues = new uint256[](3);
    address public SingularityERC721Adress;
    uint256 public reservedNFTCount;

    constructor(uint256 _reserved){
        reservedNFTCount = _reserved;
        createSortedMapping(0);}


    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    //create expansionAmount of psuedo-random numbers from randomResult
    function expand(uint256 expansionAmount) external onlyOwner{
        uint256 randomValue = randomResult;
        require(randomValue != 0, "Random Number hasn't been updated yet.");
        for (uint256 i = 0; i < expansionAmount; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
            }
    }

    function createSortedMapping(uint256 mappingSpecifier) public onlyOwner  {
        for (uint256 i = 0; i < 1111; i++){
            indexMapping[mappingSpecifier][i] = i+1 + 1111*mappingSpecifier;
        }
    }

    function shuffle(uint256 indexAmount, uint256 mappingSpecifier) external onlyOwner{ // index = 1111
        for (uint256 i = reservedNFTCount; i < indexAmount; i++) {
            uint256 n = i + uint256(keccak256(abi.encode(expandedValues[mappingSpecifier], block.timestamp))) % (indexAmount -i);
            if(reservedNFTCount > 0 && n < reservedNFTCount){
                n = n + reservedNFTCount; //This way instead of reserved NFTs, index of reservedNFT+reservedNFT gets swapped
            }

            uint256 temp = indexMapping[mappingSpecifier][n];
            indexMapping[mappingSpecifier][n] = indexMapping[mappingSpecifier][i];
            indexMapping[mappingSpecifier][i] = temp;
            }
        reservedNFTCount = 0; // Fix reservedNFTCount for future shuffles
    }

    function setNFTAddress(address newAddy) public onlyOwner{
        SingularityERC721Adress = newAddy;
    }

    function returnSpecificIdFromShuffledMapping(uint256 mappingSpecifier,uint256 index) external view returns(uint256){
        require(msg.sender == SingularityERC721Adress || msg.sender == owner());
        return indexMapping[mappingSpecifier][index];
    } 
}