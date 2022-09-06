// SPDX-License-Identifier: MIT

/*

    _//               _//                              _//
 _//   _//            _//                              _//
_//          _//    _/_/ _/   _//       _///   _//     _//_//   _//_/ _//   _////    _//
_//        _//  _//   _//   _//  _//  _//    _//  _//  _// _// _// _/  _// _//     _/   _//
_//       _//   _//   _//  _//    _//_//    _//   _//  _//   _///  _/   _//  _/// _///// _//
 _//   _//_//   _//   _//   _//  _//  _//   _//   _//  _//    _//  _// _//     _//_/
   _////    _// _///   _//    _//       _///  _// _///_///   _//   _//     _// _//  _////
                                                           _//     _//

                             ,
                              \`-._           __
                               \\  `-..____,.'  `.
                                :`.         /    \`.
                                :  )       :      : \
                                 ;'        '   ;  |  :
                                 )..      .. .:.`.;  :
                                /::...  .:::...   ` ;
                                ; _ '    __        /:\
                                `:o>   /\o_>      ;:. `.
                               `-`.__ ;   __..--- /:.   \
                               === \_/   ;=====_.':.     ;
                                ,/'`--'...`--....        ;
                                     ;                    ;
                                   .'                      ;
                                 .'                        ;
                               .'     ..     ,      .       ;
                              :       ::..  /      ;::.     |
                             /      `.;::.  |       ;:..    ;
                            :         |:.   :       ;:.    ;
                            :         ::     ;:..   |.    ;
                             :       :;      :::....|     |
                             /\     ,/ \      ;:::::;     ;
                           .:. \:..|    :     ; '.--|     ;
                          ::.  :''  `-.,,;     ;'   ;     ;
                       .-'. _.'\      / `;      \,__:      \
                       `---'    `----'   ;      /    \,.,,,/
                   `----`              fsc

*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

import "./library/AddressString.sol";


contract Catocalypse is Ownable, ERC721A, ReentrancyGuard {
    using MerkleProof for *;

    // Catllection size
    uint256 public immutable collectionSize;

    // Max group size of cats for reserve
    uint256 internal immutable maxBatchSize;

    //
    // For kitties' lovers
    //
    // Max cats per address for public mint
    uint256 public maxMintPerAddress;

    // Meownt start timestamp
    uint32 public publicStartTime;

    // Threat Price
    uint64 public publicPrice;

    // 
    // For special kitties' lovers
    //
    // Meowrkle Proof Mrroot
    bytes32 whitelistRoot;

    // Max meows per address for public mint
    uint256 public whitelistMaxMintPerAddress;

    // special threat price
    uint64 whitelistPrice;

    constructor()
    ERC721A("Catocalypse", "CAT")
    {
        maxBatchSize = 5;
        collectionSize = 6666;

        publicStartTime = uint32(block.timestamp);

        publicPrice = 0.01 ether;
        maxMintPerAddress = 50;

        whitelistPrice = 0.0075 ether;
        whitelistMaxMintPerAddress = 2;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // private sales mint function
    function whitelistMint(
        bytes32[] memory _proof,
        uint256 quantity
    )
    public
    payable
    callerIsUser
    {

        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        // Check whitelist
        bytes32 leaf = keccak256(abi.encode(msg.sender, block.chainid));
        require(MerkleProof.verify(_proof, whitelistRoot, leaf), "Whitelist is wrong");
        uint256 price = whitelistPrice;
        uint64 whitelistMinted = _getAux(msg.sender);
        require(
            whitelistMinted + quantity <= whitelistMaxMintPerAddress,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        _setAux(msg.sender, whitelistMinted + uint64(quantity));
        refundIfOver(price * quantity);
    }


    function mint(uint256 quantity)
    external
    payable
    callerIsUser
    {

        require(
            isSaleOn(publicPrice, publicStartTime),
            "sale has not begun yet"
        );
        require(
            quantity <= 10,
            "max 10 per tx"
        );
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(
            numberMinted(msg.sender) + quantity <= maxMintPerAddress,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price)
    private
    {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isSaleOn(uint256 _price, uint256 _startTime)
    internal
    view
    returns (bool) 
    {
        return _price != 0 && _startTime != 0 && block.timestamp >= _startTime;
    }

    function setTimestamp(
        uint32 timestamp
    )
    external
    onlyOwner 
    {
        publicStartTime = timestamp;
    }

    function setConfig(
        uint32 timestamp,
        uint64 _publicPrice,
        uint256 _maxMintPerAddress,
        uint64 _whitelistPrice,
        uint256 _whitelistMaxMintPerAddress
    )
    external
    onlyOwner 
    {
        publicStartTime = timestamp;
        publicPrice = _publicPrice;
        maxMintPerAddress = _maxMintPerAddress;
        whitelistPrice = _whitelistPrice;
        whitelistMaxMintPerAddress = _whitelistMaxMintPerAddress;
    }

    // For marketing etc.
    function reserve(uint256 quantity)
    external
    onlyOwner
    {
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI)
    external
    onlyOwner 
    {
        _baseTokenURI = baseURI;
    }

    function withdraw()
    external
    onlyOwner
    nonReentrant 
    {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner)
    public
    view
    returns (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) 
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function totalMinted()
    public
    view
    returns (uint256) 
    {
        return _totalMinted();
    }

    function TouchMe(string memory part)
    public
    pure
    returns (string memory)
    {
        if(keccak256(bytes(part)) == keccak256("belly")) {
            revert("DO NOT TOUCH MY BELLY");
        }
        return "purrrrrrs";
    }

    function KittyKittyKitty()
    pure
    public
    returns (string memory)
    {
        return "meooow";
    }

    function isAGoodBoy(address addr)
    view
    public
    returns (string memory)
    {
        if(addr == address(this)) {
            return "No, I'm not!";
        }

        return "Mrrr, yes!";
    }

    // Set Root for whitelist and raffle to participate in presale
    function setRoot(uint256 _root) onlyOwner() public {
        whitelistRoot = bytes32(_root);
    }
}