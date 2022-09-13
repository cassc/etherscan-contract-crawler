// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "ERC721AV4.sol";

contract Candy is ERC20Burnable, Ownable {
    bool public graviStakingLive = false;
    bool public airdropLive = false;
    uint256 public _totalSupply = 20000000 * 10**18;
    uint256 public _mintableSupply = 19000000 * 10**18;
    uint256 public _initialSupply = 1000000 * 10**18;

    uint256 public constant graviRatePerDay = 115740700000000; // 10 $CANDY per day for staked gravi

    mapping(uint256 => uint256) internal graviTimeStaked;
    mapping(uint256 => address) internal graviOwner;
    mapping(address => uint256[]) internal graviTokenIds;

    mapping(address => bool) public claimedAirdrop;
    mapping(address => uint256) addressBlockBought;
    address signer;

    address public constant graviAddress = 0xcb1dB96a5BC140861104b546d4A416b6e39f8e32;


    IERC721Enumerable private constant graviIERC721Enumerable = IERC721Enumerable(graviAddress);

    constructor(address _signer) ERC20("Candy", "CANDY") {
        signer = _signer;
        _mint(msg.sender, _initialSupply);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_TRANSACT_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(graviStakingLive, "GRAVI_STAKING_IS_NOT_YET_ACTIVE");
        }
        if(mintType == 4) {
            require(airdropLive, "CLAIMING_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function getStakedGravi(address _owner) public view returns (uint256[] memory) {
        return graviTokenIds[_owner];
    }

    function getGraviOwner(uint256 tokenId) public view returns (address) {
        return graviOwner[tokenId];
    }
    

    function toggleGraviStaking() external onlyOwner {
        graviStakingLive = !graviStakingLive;
    }


    function toggleAirdrop() external onlyOwner {
        airdropLive = !airdropLive;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function stakeGravi(uint256[] memory tokenIds) external isSecured(1) {
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(graviIERC721Enumerable.ownerOf(id) == msg.sender && graviOwner[id] == address(0), "TOKEN_IS_NOT_YOURS");
            graviIERC721Enumerable.transferFrom(msg.sender, address(this), id);
            graviTokenIds[msg.sender].push(id);
            graviTimeStaked[id] = block.timestamp;
            graviOwner[id] = msg.sender;
        }
    }



    // UNSTAKE FUNCTIONS

    function unstakeGravi(uint256[] memory tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(graviOwner[id] == msg.sender, "Not Owner");

            graviIERC721Enumerable.transferFrom(address(this), msg.sender, id);

            totalRewards += ((block.timestamp - graviTimeStaked[id]) * graviRatePerDay);
            

            removeTokenIdFromArray(graviTokenIds[msg.sender], id);
            graviOwner[id] = address(0);
        }
        if(totalSupply() <= _totalSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    // CLAIM FUNCTIONS
    function claimGravi() external {
        require(graviTokenIds[msg.sender].length > 0, "NO_STAKED_GRAVI");
        uint256 totalRewards = 0;
        uint256[] memory graviTokens = graviTokenIds[msg.sender];
        for (uint256 i = 0; i < graviTokens.length; i++) {
            uint256 id = graviTokens[i];
            require(graviOwner[id] == msg.sender, "You are not the owner");
            totalRewards += ((block.timestamp - graviTimeStaked[id]) * graviRatePerDay);
            
            graviTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function checkRewardsbyGraviIds(uint256 tokenId) external view returns (uint256) {
        require(graviOwner[tokenId] != address(0), "TOKEN_NOT_BURIED");
        uint256 totalRewards = 0;
        totalRewards += ((block.timestamp - graviTimeStaked[tokenId]) * graviRatePerDay);
        return totalRewards;
    }


    function checkAllRewardsFromGravi(address _owner) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory gravis = graviTokenIds[_owner];

        for (uint256 i = 0; i < gravis.length; i++) {
            totalRewards += ((block.timestamp - graviTimeStaked[gravis[i]]) * graviRatePerDay);
        }

        return totalRewards;
    }
    




    // AIRDROP

    function airDrop(uint256 amount, uint64 expireTime, bytes memory sig) external isSecured(4) {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, amount, expireTime));
        require(isAuthorized(sig, digest),"NOT_ELIGIBLE_FOR_AIRDROP");
        require(amount <= _mintableSupply, "AMOUNT_SHOULD_BE_LESS_THAN_SUPPLY");
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(!claimedAirdrop[msg.sender], "ALREADY_CLAIMED");

        claimedAirdrop[msg.sender] = true;
        _mint(msg.sender, amount * 1e18);
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }
}