/* SPDX-License-Identifier: UNLICENSED */
/* Copyright Metarkitex */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./lib/rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./lib/rarible/royalties/contracts/LibPart.sol";
import "./lib/rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract MetaMericanDream is Ownable, VRFConsumerBase, ERC1155Pausable, ReentrancyGuard, RoyaltiesV2Impl {
    string public name = "Metamerican Dream";
    
    uint8 public constant MAX_MINTS = 20;
    uint32 public MAX_TOKENS = 1e5;

    uint16 public tokensMinted = 0;

    address public allowlistContract;
    bool public allowlistSeason;
    
    uint256 public randomNumber;
    bytes32 public randomRequestId;
    
    bool public waitingOnRandomness;
    
    uint public cost;
    
    address payable public withdrawAddress1;
    address payable public withdrawAddress2;
    
    bytes32 private s_keyHash;
    uint256 private s_fee;

    mapping(address => uint16) public mintsPerAddress;
    mapping(uint16 => uint) public tokenIdToEncodedTraits;
    
    event SetBaseURI(string fromString, string toString);
    event SetCost(uint fromCost, uint toCost);
    event SetTokenSupply(uint fromSupply, uint toSupply);
    event LogWithdrawal(address receiver, uint amount);
    
   event FreeMint(
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    // VRFConsumerBase: Parent class for randomness consumer (https://docs.chain.link/docs/get-a-random-number/)
    // _allowlistContract: allowlist contract that can mint during allowlist period
    // withdrawAddress: set to initiator of contract
    constructor(address _allowlistContract, address vrfCoordinator, address link, bytes32 keyHash, uint256 fee, address withdrawAddress, address devWallet) ERC1155("null") VRFConsumerBase(
        vrfCoordinator, // VRF Coordinator
        link  // LINK Token
    )
    {
        // withdrawAddress for mint fees is set to contract initator
        withdrawAddress1 = payable(withdrawAddress);
        withdrawAddress2 = payable(devWallet);
        // only allowlistContract can mint while allowlistSeason == true
        allowlistContract = _allowlistContract;
        allowlistSeason = true;
        // VRF parameters
        s_keyHash = keyHash;
        s_fee = fee;
        waitingOnRandomness = true;
    }
    
    // Open minting for everybody, not just allowlistContract
    function openForMinting() external onlyOwner
    {
        allowlistSeason = false;
    }

    // Generate initial randomness request
    function initiateRandomGeneration() external onlyOwner {
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK - fill contract with faucet");
       randomRequestId = requestRandomness(s_keyHash, s_fee); 
    }  
    
    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(waitingOnRandomness, "Must be waiting on randomness");
        require(randomRequestId == requestId, "Wrong request ID");
        randomNumber=randomness;
        waitingOnRandomness=false;
    }

    // set base URI for token metadata
    function setBaseURI(string calldata base) external onlyOwner {
        emit SetBaseURI(uri(0), base);
        _setURI(base);
    }
    
    // set mint cost
    function setCost(uint newCost) external onlyOwner {
        require(cost < newCost, "price can only increase");
        emit SetCost(cost, newCost);
        cost = newCost;
    }

    function setTokenSupply(uint32 newSupply) external onlyOwner {
        require(MAX_TOKENS > newSupply, "supply can only decrease");
        emit SetTokenSupply(MAX_TOKENS, newSupply);
        MAX_TOKENS = newSupply;
    }

    function mint(address _to, uint16 quantity, bool freeMint) external payable {
        // This contract should only mint up to MAX_TOKENS in its lifetime
        require(tokensMinted + quantity <= MAX_TOKENS);
        // Each recipient can only mint MAX_MINTS
        require(mintsPerAddress[_to] + quantity <= MAX_MINTS);
        mintsPerAddress[_to] += quantity;
        // only allowlistContract can mint during allowlist period, otherwise you can only mint for yourself
        require((!allowlistSeason && _to == _msgSender()) || allowlistContract == _msgSender());
        // either message contains mint fee or this is a free mint
        require(msg.value == (cost * quantity) || (allowlistContract == _msgSender() && freeMint));
        // generate list of token IDs by hashing result of initial randomness
        uint[] memory _ids = new uint[](quantity);
        uint[] memory _quantities = new uint[](quantity);
        for (uint16 i = 0; i < quantity; i++) {
            randomNumber = uint256(keccak256(abi.encode(randomNumber)));
            _ids[i] = tokensMinted + 1 + i;
            tokenIdToEncodedTraits[tokensMinted + 1 + i] = randomNumber;
            _quantities[i] = 1;
        }
        tokensMinted += quantity;
        super._mintBatch(_to, _ids, _quantities, "");
        // publish free mint event to show free mints
        if (freeMint) {
            emit FreeMint(_to, _ids, _quantities);
        }
    }
    
    // withdraw all funds to admin wallet
    function withdraw(uint amount) external onlyOwner nonReentrant {
        (bool success1, ) = withdrawAddress1.call{value: (amount*99)/100}(msg.data);
        (bool success2, ) = withdrawAddress2.call{value: amount/100}(msg.data);
        require(success1 && success2, "Transfer failed");
        emit LogWithdrawal(withdrawAddress1, amount*99/100);
        emit LogWithdrawal(withdrawAddress2, amount/100);
    }
    
    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}