// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/IERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NftStake is ERC721AUpgradeable, ERC721Holder, OwnableUpgradeable {
    uint16 public maxUserStake;
    uint256 public updateStakeDays;
    uint[] public stakingUsers;
    address[] public stakingNftAddress;
    mapping (string => address) public stakingNew;

    struct Staking {
        address user;
        uint256 isStake;
        uint256 typeContract;
        uint256 daysStake;
        uint256 tokenuserId;
    }


    function initialize() initializerERC721A initializer public {
        __ERC721A_init('TestStaking', 'Test');
        __Ownable_init();
        updateStakeDays = 90;
        maxUserStake = 10000;
    }

    function addNftContract(address nft_) public onlyOwner {
        stakingNftAddress.push(nft_);
    }

    function updateMaxUserStake (uint16 _count) public onlyOwner {
        maxUserStake = _count;
    }

    function stake (uint256 tokenId, uint256 _type) external {
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);

        _nft.safeTransferFrom(msg.sender, address(this), tokenId);
        stakingNew[string(abi.encodePacked(Strings.toString(tokenId), Strings.toString(_type)))] = msg.sender;
    }

    function unstake (uint64 tokenId, uint8 _type, uint256 _index) external {
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);
        if (stakingNew[string(abi.encodePacked(Strings.toString(tokenId), Strings.toString(_type)))] == address(0) && _index != 9999) {
            uint256 params = stakingUsers[_index];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            require(owner == msg.sender, "You can't unstake");
            _nft.safeTransferFrom(address(this), msg.sender, tokenId);
            //delete(stakingUsers[_index]);
        } else {
            require(stakingNew[string(abi.encodePacked(Strings.toString(tokenId), Strings.toString(_type)))] == msg.sender, "You can't unstake");

            _nft.safeTransferFrom(address(this), msg.sender, tokenId);

            delete stakingNew[string(abi.encodePacked(Strings.toString(tokenId), Strings.toString(_type)))];
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setParams(address owner, uint256 isStake, uint256 daysStake, uint256 typeContract, uint256 tokenuserId)
    external {
        uint256 params = uint256(uint160(owner));
        params |= isStake<<160;
        params |= daysStake<<208;
        params |= typeContract<<224;
        params |= tokenuserId<<240;

        stakingUsers.push(params);
    }

    function getParams(uint256 tokenId, uint256 _type) external view returns(address , uint256 , uint256 , uint256 , uint256 ) {
        uint256 i = 0;
        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));

            if (tokenuserId == tokenId &&  typeContract == _type) {
                return (owner, isStake, daysStake, typeContract, tokenuserId);
            }

            i++;
        }
    }

    function updateStakeDay(uint256 tokenId, uint256 _type) external {

    }

    function getNftAddress() public view returns (address[] memory) {
        return stakingNftAddress;
    }

    function getNftStaking() public view returns (Staking[] memory ){
        uint256 i = 0;
        Staking[] memory stakingNft = new Staking[](stakingUsers.length);

        while (i < stakingUsers.length) {
            uint256 params = stakingUsers[i];
            address owner = address(uint160(params));
            uint256 isStake = uint256(uint40(params>>160));
            uint256 daysStake = uint256(uint16(params>>208));
            uint256 typeContract = uint256(uint16(params>>224));
            uint256 tokenuserId = uint256(uint16(params>>240));
            stakingNft[i] = Staking(owner, isStake, typeContract, daysStake, tokenuserId);

            i++;
        }

        return stakingNft;
    }

    function manyStaking(uint256[] calldata _tokenIds, uint256 _type) external {
        uint256 len = _tokenIds.length;
        IERC721AUpgradeable _nft = IERC721AUpgradeable(stakingNftAddress[_type]);
        for (uint256 i; i < len; ++i) {

            _nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            stakingNew[string(abi.encodePacked(Strings.toString(_tokenIds[i]), Strings.toString(_type)))] = msg.sender;
        }
    }

    function manyUpdateStakeDay(uint256[] calldata _tokenIds, uint256 _type) external {
        uint256 len = _tokenIds.length;
    }
}