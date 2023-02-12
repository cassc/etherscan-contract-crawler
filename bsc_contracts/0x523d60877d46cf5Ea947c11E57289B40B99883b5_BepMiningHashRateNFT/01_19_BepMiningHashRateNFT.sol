// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./file/String.sol";
import "./file/Counters.sol";
import "./file/Address.sol";
import "./file/Ownable.sol";
import "./file/ERC165.sol";
import "./file/ERC721.sol";
import "./file/IAccessControl.sol";
import "./file/AccessControlEnumerable.sol";
import "./file/ERC721Enumerable.sol";

contract BepMiningHashRateNFT is
    ERC721,
    AccessControlEnumerable,
    ERC721Enumerable,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _counts;
    uint256 defaultItem = 3624;

    mapping(address => bool) public approvalWhitelists;
    string private _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct NFTInfo {
        uint256 tokenId;
        uint256 createdDate;
    }

    struct HashrateInfo {
        address user;
        uint256 power;
        string miner;
        uint256 capitalUSDT;      
        uint256 createdDateAt;
        uint256 remainTimeMining;
        uint256 timeActive;
        bool isActive;
        bool nonPayActive;
        uint256 tokenId;
        address addressMining;
    }

    mapping(address => HashrateInfo[]) public hashrateLists;

    event TokenMinted(address to, uint256 indexed tokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _setupRole(MINTER_ROLE, _msgSender());
        _counts.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setNewMinter(address addressMinter) external onlyOwner {
        _setupRole(MINTER_ROLE, addressMinter);
    }

    function getNftFromAddress(address user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balanceNFT = balanceOf(user);
        uint256[] memory tokens = new uint256[](balanceNFT);
        for (uint256 i = 0; i < balanceNFT; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            tokens[i] = tokenId;
        }
        return tokens;
    }

    function getCurrentIndexOfTokenId(uint256 tokenId, address user)
        public
        view
        returns (uint256, bool)
    {
        uint256 index = 0;
        bool status = false;
        for (uint256 i = 0; i < hashrateLists[user].length; i++) {
            if (hashrateLists[user][i].tokenId == tokenId) {
                index = i;
                status = true;
                break;
            }
        }
        return (index, status);
    }

    function getListHashrateOfUser(address user) public view returns(HashrateInfo[] memory) {
        return hashrateLists[user];
    } 

    function getInfoHashrate(uint256 tokenId, address user)
        public
        view
        returns (
            uint256 power,
            uint256 capitalUSDT,           
            uint256 remainTimeMining,
            uint256 timeActive,
            bool isActive,
            bool nonPayActive,
            uint256 index,
            bool status
        )
    {
        for (uint256 i = 0; i < hashrateLists[user].length; i++) {
            if (hashrateLists[user][i].tokenId == tokenId) {
                power = hashrateLists[user][i].power;
                capitalUSDT = hashrateLists[user][i].capitalUSDT;             
                remainTimeMining = hashrateLists[user][i].remainTimeMining;
                timeActive = hashrateLists[user][i].timeActive;
                isActive = hashrateLists[user][i].isActive;
                nonPayActive = hashrateLists[user][i].nonPayActive;
                index = i;
                status = true;
                break;
            }
        }
        return (
            power,
            capitalUSDT,           
            remainTimeMining,
            timeActive,
            isActive,
            nonPayActive,
            index,
            status
        );
    }

    function approvalBuild(
        address to,
        uint256 power,
        string memory miner,
        uint256 capitalUSDT,     
        uint256 remainTime,
        address addressMining
    ) external returns (uint256) {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        uint256 itemId = _counts.current() + defaultItem;
        require(!_exists(itemId), "NFT: must have unique tokenId");
        _mint(to, itemId);
        _counts.increment();

        hashrateLists[to].push(
            HashrateInfo(
                to,
                power,
                miner,
                capitalUSDT,              
                block.timestamp,
                remainTime,
                0,
                false,
                true,
                itemId,
                addressMining
            )
        );
        emit TokenMinted(to, itemId);
        return itemId;
    }

    function approvalEditNonPayActive(
        address user,
        uint256 index,
        bool status
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        hashrateLists[user][index].nonPayActive = status;
    }

    function approvalActive(uint256 index, address user) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        require(
            hashrateLists[user][index].isActive == false,
            "NFT: Hashrate activate"
        );
        hashrateLists[user][index].nonPayActive = false;
        hashrateLists[user][index].isActive = true;
        hashrateLists[user][index].timeActive = block.timestamp;
    }

    function approvalReactive(
        uint256 index,
        address user,       
        uint256 remainTime
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        require(
            hashrateLists[user][index].isActive == false,
            "NFT: Hashrate activate"
        );
        hashrateLists[user][index].nonPayActive = true;
        hashrateLists[user][index].isActive = true;
        hashrateLists[user][index].timeActive = block.timestamp;
        hashrateLists[user][index].remainTimeMining = remainTime;        
    }

    function approvalDeactive(uint256 index, address user) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        require(
            hashrateLists[user][index].isActive == true,
            "NFT: Hashrate deactive"
        );
        hashrateLists[user][index].isActive = false;
    }

    function approvalDestroy(uint256 index, address user) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        uint256 tokenId = hashrateLists[user][index].tokenId;
        _burn(tokenId);
    }

    function balanceHashrateOfUser(address user) external view returns (uint256) {
        return hashrateLists[user].length;
    }

    function approvalUpdateTimeActive(
        uint256 index,
        address user,
        uint256 time
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "NFT: must have minter role to mint"
        );
        hashrateLists[user][index].timeActive = time;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (approvalWhitelists[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function addApprovalWhitelist(address proxy) public onlyOwner {
        require(
            approvalWhitelists[proxy] == false,
            "NFT: invalid proxy address"
        );

        approvalWhitelists[proxy] = true;
    }

    function removeApprovalWhitelist(address proxy) public onlyOwner {
        approvalWhitelists[proxy] = false;
    }

    function updateBaseURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        require(from != to, "NFT: no same address");

        super._beforeTokenTransfer(from, to, tokenId);

        uint256 index = 0;
        bool status = false;
        (index, status) = getCurrentIndexOfTokenId(tokenId, from);
        if (status == true && from != address(0)) {
            if (to != address(0)) {
                hashrateLists[to].push(
                    HashrateInfo(
                        to,
                        hashrateLists[from][index].power,
                        hashrateLists[from][index].miner,
                        hashrateLists[from][index].capitalUSDT,                       
                        hashrateLists[from][index].createdDateAt,
                        hashrateLists[from][index].remainTimeMining,
                        hashrateLists[from][index].timeActive,
                        false,
                        true,
                        hashrateLists[from][index].tokenId,
                        hashrateLists[from][index].addressMining
                    )
                );
            }
            for (uint256 i = index; i < hashrateLists[from].length - 1; i++) {
                hashrateLists[from][i] = hashrateLists[from][i + 1];
            }
            hashrateLists[from].pop();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}