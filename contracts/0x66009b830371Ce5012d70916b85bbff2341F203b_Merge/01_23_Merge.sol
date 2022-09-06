// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Sentence.sol";

contract Merge is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard, IERC721Receiver {
    // lib
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // struct
    struct MergeInfo{
        uint256 sentenceTokenID;

        address erc721Address;
        uint256 erc721TokenID;

        address mergeAddress;

        uint256 reward;
    }
    
    // constant

    // storage
    IERC20 public rewardToken;
    uint256 private _counter;
    string private _basePath;

    mapping(uint256=>MergeInfo) public mergeInfos;
    mapping(address=>uint256) public erc721Rewards;
    uint256 public minRewards = 1 ether;

    IERC721 public senteceAddress;

    // event
    event Bind(address indexed to, address indexed erc721Address, uint256 erc721TokenID, uint256 sentenceTokenID);
    event Unbind(address indexed from, address indexed erc721Address, uint256 erc721TokenID, uint256 sentenceTokenID);

    constructor(address _rewardToken, address _sentenceAddress) ERC721("Merge", "MG") {
        rewardToken = IERC20(_rewardToken);
        senteceAddress = IERC721(_sentenceAddress);
    }

    function bind(address erc721Address, uint256 erc721TokenID, uint256 sentenceTokenID) public nonReentrant{
        senteceAddress.safeTransferFrom(msg.sender, address(this), sentenceTokenID);
        (IERC721(erc721Address)).safeTransferFrom(msg.sender, address(this), erc721TokenID);

        _counter++;
        _mint(msg.sender, _counter);
        mergeInfos[_counter].sentenceTokenID = sentenceTokenID;
        mergeInfos[_counter].erc721Address = erc721Address;
        mergeInfos[_counter].erc721TokenID = erc721TokenID;
        mergeInfos[_counter].mergeAddress = msg.sender;
        uint256 reward = erc721Rewards[erc721Address];
        if (reward <= 0){
            reward = minRewards;
        }
        mergeInfos[_counter].reward = reward;
        
        if (reward > 0){
            uint256 balance = rewardToken.balanceOf(address(this));
            if (reward > balance){
                reward = balance;
            }

            if (reward > 0){
                rewardToken.safeTransfer(msg.sender, reward);
            }
        }

        emit Bind(msg.sender, erc721Address, erc721TokenID, sentenceTokenID);
    }

    function unbind(uint256 tokenID) public nonReentrant{
        require(ownerOf(tokenID) == msg.sender, "unbind caller is not owner");

        _burn(tokenID);
        senteceAddress.safeTransferFrom(address(this), msg.sender, mergeInfos[tokenID].sentenceTokenID);
        (IERC721(mergeInfos[tokenID].erc721Address)).safeTransferFrom(address(this), msg.sender, mergeInfos[tokenID].erc721TokenID);

        uint256 reward = mergeInfos[tokenID].reward;
        if (reward > 0){
            rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        }

        emit Unbind(msg.sender, mergeInfos[tokenID].erc721Address, mergeInfos[tokenID].erc721TokenID, mergeInfos[tokenID].sentenceTokenID);
    }

    function bindReward(address erc721Address) public view returns(uint256){
        return erc721Rewards[erc721Address];
    }

    function setBindReward(address[] memory erc721Address, uint256[] memory amounts) public onlyOwner{
        for (uint256 i = 0; i < erc721Address.length; ++i){
            erc721Rewards[erc721Address[i]] = amounts[i];
        }
    }

    function setBindMinReward(uint256 _minReward) public onlyOwner{
        minRewards = _minReward;
    }

    // url
    function setBaseURI(string calldata path) public onlyOwner {
        _basePath = path;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(_basePath, tokenId.toString()));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address ,
        address ,
        uint256 ,
        bytes calldata 
    ) external virtual override returns (bytes4){
        return this.onERC721Received.selector;
    }
}