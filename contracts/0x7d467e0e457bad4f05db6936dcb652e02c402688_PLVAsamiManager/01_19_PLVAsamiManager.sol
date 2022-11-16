//
//  ________  ___       ___      ___
// |\   __  \|\  \     |\  \    /  /|
// \ \  \|\  \ \  \    \ \  \  /  / /
//  \ \   ____\ \  \    \ \  \/  / /
//   \ \  \___|\ \  \____\ \    / /
//    \ \__\    \ \_______\ \__/ /
//     \|__|     \|_______|\|__|/
//
// Paralverse Asami Minter
//
// by @G2#5600
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/IERC721A.sol";
import "../../interfaces/IPLVAsami.sol";
import "../../interfaces/IPLVAsamiMeta.sol";
import "../../utils/PLVErrors.sol";

contract PLVAsamiManager is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    address public asamiContract;
    address public asamiMeta;
    address public plvContract;
    uint256 public mintPrice;
    uint256 public updatePrice;
    uint256 public namePrice;

    struct PlayerStatus {
        uint256 status;
        uint256 timestamp;
    }

    /// @dev token status
    mapping(uint256 => PlayerStatus) public players;
    /// @dev reveal status
    mapping(uint256 => bool) public revealed;

    /* ==================== METHODS ==================== */

    /**
     * @dev contract intializer
     *
     * @param _asami asami contract address
     * @param _meta meta contract address
     */
    function initialize(
        address _asami,
        address _meta,
        address _plv
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        asamiContract = _asami;
        asamiMeta = _meta;
        plvContract = _plv;

        mintPrice = 0.33 ether;
        updatePrice = 100 ether;
        namePrice = 500 ether;
    }

    /**
     * @dev public mint
     *
     * @param _qty mint quantity
     */
    function mint(uint256 _qty) external payable whenNotPaused nonReentrant {
        if (msg.value < _qty * mintPrice || _qty == 0) revert InvalidAmount();

        IPLVAsami asami = IPLVAsami(asamiContract);
        asami.mint(_msgSender(), _qty);
    }

    /**
     * @dev set the asami's own name
     *
     * @param _id token id
     * @param _name new name
     */
    function updateName(uint256 _id, string memory _name) external whenNotPaused nonReentrant {
        if (IERC721A(asamiContract).ownerOf(_id) != _msgSender()) revert InvalidOwner();

        IERC20 plv = IERC20(plvContract);
        plv.transferFrom(_msgSender(), address(this), namePrice);

        IPLVAsamiMeta meta = IPLVAsamiMeta(asamiMeta);
        meta.setName(_id, _name);
    }

    /**
     * @dev update the meta attribute of nft
     *
     * @param _id token id
     */
    function update(uint256 _id) external whenNotPaused nonReentrant {
        if (IERC721A(asamiContract).ownerOf(_id) != _msgSender()) revert InvalidOwner();
        if (!revealed[_id]) revert NotRevealed();

        IERC20 plv = IERC20(plvContract);
        plv.transferFrom(_msgSender(), address(this), updatePrice);

        IPLVAsamiMeta meta = IPLVAsamiMeta(asamiMeta);
        meta.rebuild(_msgSender(), _id);
    }

    /**
     * @dev asami can change status to play/work/idle to earn PLV or sale
     *      0: idle status
     * @param _id token id
     */
    function play(uint256 _id, uint256 _status) external whenNotPaused {
        if (IERC721A(asamiContract).ownerOf(_id) != _msgSender()) revert InvalidOwner();
        players[_id].status = _status;
        players[_id].timestamp = block.timestamp;
    }

    /**
     * @dev reveal the NFT
     *
     * @param _ids array of nft ids
     */
    function reveal(uint256[] memory _ids) external whenNotPaused {
        IPLVAsamiMeta meta = IPLVAsamiMeta(asamiMeta);

        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            uint256 id = _ids[i];

            if (IERC721A(asamiContract).ownerOf(id) != _msgSender()) revert InvalidOwner();
            if (revealed[id] == true) revert AlreadyRevealed();

            meta.build(_msgSender(), id, 1);
            revealed[id] = true;
            unchecked {
                ++i;
            }
        }
    }

    /* ==================== GETTER METHODS ==================== */

    /**
     * @dev returns the nft status, make it zero to transfer
     *
     * @param _id nft id
     */
    function statusOf(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IPLVAsamiMeta meta = IPLVAsamiMeta(asamiMeta);
        uint256 data = meta.metaOf(_id);
        return (players[_id].status, players[_id].timestamp, data);
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev Owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner can withdraw the eth
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Owner can withdraw the plv token
     */
    function withdrawPLV() external onlyOwner {
        IERC20 plv = IERC20(plvContract);
        plv.transferFrom(address(this), owner(), plv.balanceOf(address(this)));
    }

    /**
     * @dev Owner can set mint price
     *
     * @param _mintPrice single mint price
     * @param _updatePrice single update price
     */
    function setPrice(uint256 _mintPrice, uint256 _updatePrice) external onlyOwner {
        mintPrice = _mintPrice;
        updatePrice = _updatePrice;
    }

    /**
     * @dev Owner can mint privately
     *
     * @param _qty mint quantity
     */
    function privateMint(uint256 _qty) external onlyOwner {
        IPLVAsami asami = IPLVAsami(asamiContract);
        asami.mint(_msgSender(), _qty);
    }

    /**
     * @dev Owner can reveal the multiple NFTs privately
     *
     * @param _ids array of nft ids
     */
    function privateReveal(uint256[] memory _ids) external onlyOwner {
        IPLVAsamiMeta meta = IPLVAsamiMeta(asamiMeta);

        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; ) {
            uint256 id = _ids[i];
            if (revealed[id] == true) revert AlreadyRevealed();

            meta.build(_msgSender(), id, 1);
            revealed[id] = true;
            unchecked {
                ++i;
            }
        }
    }
}