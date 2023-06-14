// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
///@title Frens Pool Share NFT
///@author 0xWildhare and FRENS team
///@dev see ERC721

import "./interfaces/IFrensPoolShareTokenURI.sol";
import "./interfaces/IFrensArt.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "hardhat/console.sol";

contract FrensPoolShare is
    IFrensPoolShare,
    ERC721Enumerable,
    AccessControl,
    Ownable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    IFrensStorage frensStorage;

    //maps each ID to the pool that minted it
    mapping(uint => address) public poolByIds;

    ///@dev sets the storage contract and the token name/symbol
    constructor(IFrensStorage frensStorage_) ERC721("FRENS Share", "FRENS") {
        frensStorage = frensStorage_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    ///@dev callable by the staking pools only
    function mint(address userAddress) public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "you are not allowed to mint"
        );
        uint256 _id = totalSupply();
        poolByIds[_id] = address(msg.sender);
        _safeMint(userAddress, _id);
    }

    function exists(uint _id) public view returns (bool) {
        return _exists(_id);
    }

    function getPoolById(uint _id) public view returns (address) {
        return (poolByIds[_id]);
    }

    ///@dev stakingPool is allowed during rageQuit, so the user cannot block the sale of the NFT by changing the allow
    function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        _requireMinted(tokenId);
        address poolAddr = poolByIds[tokenId];
        IStakingPool stakingPool = IStakingPool(poolAddr);
        (/*price*/,/*time*/, bool quitting) = stakingPool.rageQuitInfo(tokenId);
        if(quitting) {
            return poolAddr;
        } else{
            return super.getApproved(tokenId);
        }
        
    }

    function tokenURI(
        uint256 id
    ) public view override(ERC721, IFrensPoolShare) returns (string memory) {
        IFrensPoolShareTokenURI frensPoolShareTokenURI = IFrensPoolShareTokenURI(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShareTokenURI"))));
        return frensPoolShareTokenURI.tokenURI(id);
    }

    function renderTokenById(uint256 id) public view returns (string memory) {
        IStakingPool pool = IStakingPool(getPoolById(id));
        IFrensArt frensArt = pool.artForPool();
        return frensArt.renderTokenById(id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId,
        uint batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        IStakingPool pool = IStakingPool(poolByIds[tokenId]);
        if (from != address(0) && to != address(0)) {
            require(pool.locked(tokenId) == false, "not transferable");
        }
    }

    function burn(uint tokenId) public {
        require(
            msg.sender == address(poolByIds[tokenId]),
            "cannot burn shares from other pools"
        );
        _burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}