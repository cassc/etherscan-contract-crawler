// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "hardhat/console.sol";

/**
* @title jpegMe
* @author royce.eth 
* @notice NFT Messenging App
 */
contract Messenger is ERC721, ERC721Burnable, Ownable {
    
    /**
    * @notice Emmits an event when either mint function is called. Can be emitted without an actual NFT being minted.
    * @param sender Sender of the Message
    * @param to Receipient of the Message
    * @param value The text body content of the message
    * @param nft true if mint was called and a NFT was created/updated, false if mintEvent was called and no on-chain data altered
     */
    event SentMessage(address indexed sender, address indexed to, string value, bool nft);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    using Strings for uint;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) public optOut;
    uint public fee = 0;
    address public metaAddress;
    string public uriData = "https://jpegme.herokuapp.com/";

    constructor() payable ERC721("jpegMe", "JPM") {}


    /**
    * @notice Mint a new NFT message or update an existing one, and emit the NFT event.
     */
    function mint(address _to, string memory _userText) public payable {
        require(optOut[_to] == false, "User has opted out of receiving messasges");

        if (msg.sender != owner()) {
            require(msg.value >= fee, "eth value is below expected fee");
        }

        //if the receiver doesn't have an NFT record yet, mint one
        if(!userHasNFT(_to)){
            _tokenIdCounter.increment();
            uint256 _tokenId = _tokenIdCounter.current();
            _safeMint(_to, _tokenId);
        } else { //user does have an NFT already, so lets update its meta data with the new message. I don't want to use the gas to loop through to find the receivers NFT token id, so update them all.
            emit BatchMetadataUpdate(0, type(uint256).max );
        }
        
        emit SentMessage(msg.sender, _to, _userText, true);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 tokenId)
        internal virtual override
    {
        super._beforeTokenTransfer(_from, _to, tokenId);
        //if you transfer a message, transfer message to new user and update the from, delete senders message record
        bool minting = (_from == address(0)); //!_exists(tokenId); //if token doesn't already exist, its being minted
        
        //Case: User is transferring an existing NFT (didn't call mint) 
        if(!minting){
            //Case: Burning
            if(_to == address(0)) {
                 optOut[msg.sender] = true; 
            } //if you are burning a token, lets opt you out since you probably don't want another one!
            else {
                //Case: User is transferring NFT to user who already has one and we will prevent them in case it overwites a genesis theme
                require(!userHasNFT(_to), "Wallet already has a Message and can only have one");
                //console.log("We are transferring a token that isn't being minted");
            }
        } 
    }

    //convert address to string
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
    
    function tokenURI(uint256 _tokenid)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenid),
            "erc721metadata: uri query for nonexistent token"
        );

        string memory fullURI = string(
            abi.encodePacked(
                uriData,
                '?address=0x',
                toAsciiString(ownerOf(_tokenid)),
                '&tokenid=',
                _tokenid.toString()
            )
        );
        return fullURI;
    }

    function tokenSupply() public view returns(uint){
        return _tokenIdCounter.current();
    }

    function updateFee(uint _fee) external onlyOwner {
        fee = _fee;
    }

    function userHasNFT(address _to) public view returns(bool) {
        return balanceOf(_to) != 0;
    }

    function changeOptOut() public {
        optOut[msg.sender] = !optOut[msg.sender];
    }
    
    function setUri(string memory _uriData) external onlyOwner {
        uriData =  _uriData;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
    receive() external payable {
        // Receive function logic here
    }
}