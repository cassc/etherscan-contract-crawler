// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface CratesInterface {

    function balanceOf(address account,uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract OpenCrates is VRFConsumerBaseV2, ERC1155Supply, Ownable   {
    address constant public CratesAddress = 0xC50F11281b0821E5a9AD3DD77C33Eaf82d3094f4;
    address constant public BurnAddress = 0x000000000000000000000000000000000000dEaD;
    bool public saleIsActive = false;
    string private _baseTokenURI;
    uint private acumulate_0;
    uint private seed;

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId; // get subscription ID from vrf.chain.link
    bytes32 private immutable i_keyHash;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    event seedRequested(uint256 indexed requestId);

    constructor(string memory _uri, address vrfCoordinatorV2Address, uint64 subId, bytes32 keyHash, uint32 callbackGasLimit, uint _seed)

    VRFConsumerBaseV2(vrfCoordinatorV2Address)
    ERC1155(_uri)
    {
        setURI(_uri);
        seed = _seed;
        // VRF variables
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Address);
        i_subscriptionId = subId;
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
    }

    function setSeed()  public returns (uint256 requestId) {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash, //
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // emit an event
        emit seedRequested(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(requestId > 0);
        seed = randomWords[0] % 100;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function setURI(string memory newuri) public onlyOwner {
        _baseTokenURI = newuri;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function totalAvailable(address ownwer) external view returns (uint) {
        uint value = CratesInterface(CratesAddress).balanceOf(ownwer,77);
        return value;
    }

    function mint(uint numberOfTokens) public  {
        require(saleIsActive, "Sale must be active to mint Tokens");
        uint value = CratesInterface(CratesAddress).balanceOf(msg.sender,77);
        require(numberOfTokens <= value, "Value is not correct");
        CratesInterface(CratesAddress).safeTransferFrom(msg.sender,BurnAddress,77,numberOfTokens,"0x");
        uint _seed = seed;
        seed+=1;
        for (uint i = 0; i < numberOfTokens; i++) {
              uint8 number = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.timestamp),_seed)))%127)+1;
              _seed+=number;
              uint8 number2 = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1),_seed)))%99);
              if (number < 8) {
                  if (totalSupply(number) > 6 || number2 > 20) {
                       number =number+71;
                  }
              } else if (number < 32) {
                  if (totalSupply(number) > 23 || number2 > 50) {
                       number =number+71;
                  }
              } else if (number < 72) {
                   if (totalSupply(number) > 49 || number2 > 90) {
                       number =number+56;
                   }
              }
              _mint(msg.sender, number, 1, "");
        }


    }

}