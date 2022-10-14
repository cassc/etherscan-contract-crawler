// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./ReEntrancyGuard.sol";

contract VIAINS is
    Ownable,
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    ERC721Royalty,
    VRFConsumerBase,
    ReEntrancyGuard
{
    /// @dev  NFT metadata
    string[] IpfsUri = [
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/0.json",
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/1.json",
        "https://daiki-dev.mypinata.cloud/ipfs/QmemVnmqFnyddyyknhieKRjbzWNQa2nGdn2RadwWesjCkK/2.json"
    ];

    /// @dev is sale active
    bool public isSaleActive = true; // Is the sale active?

    /// @dev max mint per transaction
    uint public MAX_MINT_PER_WALLET = 2; // Maximum number of tokens that can be minted per transaction

    /// @dev max supply
    uint public MAX_SUPPLY = 0; // Maximum limit of tokens that can ever exist

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    address LinkToken = address(0);

    mapping(bytes32 => address) requestToSender;

    /// @dev register owner del token
    mapping(uint256 => uint256) public userMintCount;

    struct Buyer {
        address buyed;
        uint256 amount;
    }
    mapping(uint256 => Buyer) public buyTokensID; // tokenID => Buyer

    struct Character {
        uint256 lvl;
    }

    Character[] public characters;

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,
        string memory _name,
        string memory _symbol,
        uint256 _totalsupply,
        address _addressRoyalty,
        uint96 _fee
    ) ERC721(_name, _symbol) VRFConsumerBase(_VRFCoordinator, _LinkToken) {
        MAX_SUPPLY = _totalsupply; // Maximum limit of tokens that can ever exist
        LinkToken = _LinkToken; // Link Token address
        keyHash = _keyHash; // VRF key hash
        fee = 0.1 * 10**18; // 0.1 LINK

        /// @dev set the address of the  contract
        _setDefaultRoyalty(_addressRoyalty, _fee);
    }

    /// @dev hook for ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        /// @dev count buyer
        uint256 countBuyer = userMintCount[tokenId];

        /// @dev count buyer
        userMintCount[tokenId] = countBuyer + 1;

        /// @dev save the buyer
        buyTokensID[countBuyer] = Buyer(to, 0);

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @dev hook for ERC721
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /// @dev set the address of the Lnda contract
    function setDefaultRoyalty(address _owner, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_owner, _feeNumerator);
    }

    /// @dev super method for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @dev  mint NFT
    function mintToken() external noReentrant returns (bytes32) {
        require(isSaleActive, "Mint Token: Sale isn't active");

        require(
            LINK.balanceOf(address(this)) >= fee,
            "Mint Token:  Not enough LINK - fill contract with faucet"
        );

        require(characters.length < 9999, "Mint Token: Max suply is mint"); /// @dev max supply

        /// @dev amount of tokens to mint
        uint _amount = 1;

        /// @dev get total supply
        uint256 supply = totalSupply();

        /// @dev balance token
        uint256 tokenCount = balanceOf(_msgSender());
        require(
            tokenCount < MAX_MINT_PER_WALLET,
            "Mint Token: You have reached the max limit"
        );

        require(
            supply + _amount <= MAX_SUPPLY,
            "Mint Token: Can't mint more than max supply"
        );

        bytes32 requestId = requestRandomness(keyHash, fee); // VRF request

        requestToSender[requestId] = _msgSender(); // Save the sender's address

        return requestId;
    }

    /// @dev  ful fil the requestq
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        uint256 newId = characters.length; // get the new id
        uint256 toEv = ((randomNumber % 1000000000000) / 10000000000); /// get the random number
        uint256 lvl = evalRandom(toEv); /// eval the random number

        /// @dev create the character
        characters.push(Character(lvl));

        /// @dev count buyer
        uint256 countBuyer = userMintCount[newId];

        /// @dev get sender
        address _sender = requestToSender[requestId];

        /// @dev mint the token
        _safeMint(_sender, newId);

        /// @dev set the token URI
        _setTokenURI(newId, IpfsUri[lvl]);

        /// @dev count buyer
        userMintCount[newId] = countBuyer + 1;

        /// @dev save the buyer
        buyTokensID[countBuyer] = Buyer(_sender, 0);
    }

    /// @dev eval the random number
    function evalRandom(uint256 num) internal pure returns (uint256) {
        if ((num % 3) == 0) {
            return 2;
        }
        if ((num % 2) == 0) {
            return 1;
        }
        return 0;
    }

    /// @dev withdraw LINK from this contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LinkToken);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /// @dev set active sale
    function activeSale(bool newValue) public onlyOwner {
        isSaleActive = newValue;
    }
}