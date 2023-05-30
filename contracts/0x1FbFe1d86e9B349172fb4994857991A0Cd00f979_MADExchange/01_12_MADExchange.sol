/* @author
 * ___ ___   ___    ___   ____    ____  ____   ___  _       ____  ____
 * |   |   | /   \  /   \ |    \  /    ||    \ /  _]| |     /    ||    \
 * | _   _ ||     ||     ||  _  ||  o  ||  o  )  [_ | |    |  o  ||  o  )
 * |  \_/  ||  O  ||  O  ||  |  ||     ||   _/    _]| |___ |     ||     |
 * |   |   ||     ||     ||  |  ||  _  ||  | |   [_ |     ||  _  ||  O  |
 * |   |   ||     ||     ||  |  ||  |  ||  | |     || end ||  |  || re  |
 * |___|___| \___/  \___/ |__|__||__|__||__| |_____||_____||__|__||_____|
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity "0.8.17";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error MADExchange_NotOpen();
error MADExchange_MustBeClosed();
error MADExchange_MutantSellingNotOpen();
error MADExchange_ContractIsOutOfMAD();
error MADExchange_NotTheOwnerOfToken();
error MADExchange_NoTokenSendt();
error MADExchange_ContractIsMissing();
error MADExchange_TooManyTokens();

interface IMoonStaking {
    function getTokenYield(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function getStakerNFT(
        address staker
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MADExchange is ERC1155Holder, Ownable, ReentrancyGuard {
    IERC1155 public pet;
    IERC721 public loot;
    IERC20 public mad;
    IMoonStaking public orgStaking;
    IERC721 public breeding;

    mapping(uint256 => uint256) private _petMADrate;
    mapping(uint256 => uint256) private _mutantTypeRate;
    mapping(uint256 => uint256) private _lootMADrate;
    address private LOOT_CONTRACT;

    bool public isMADExchangeOpen;
    bool public mutantSalesStatus;
    address public mutantBuyerAddress;

    event BurnPets(address, uint256);
    event BurnLoot(address, uint256);
    event SellMutant(address, uint256);

    address DEAD;

    constructor(address _mad, address _orgStaking) {
        mad = IERC20(_mad);
        orgStaking = IMoonStaking(_orgStaking);

        isMADExchangeOpen = false;
        mutantSalesStatus = false;

        _petMADrate[0] = 1000000000000000000;
        _petMADrate[1] = 1250000000000000000;
        _petMADrate[2] = 1500000000000000000;
        _petMADrate[3] = 1750000000000000000;
        _petMADrate[4] = 2000000000000000000;
        _petMADrate[5] = 2250000000000000000;
        _petMADrate[6] = 2500000000000000000;

        _lootMADrate[12] = 1300000000000000000;
        _lootMADrate[15] = 1500000000000000000;
        _lootMADrate[20] = 1700000000000000000;
        _lootMADrate[30] = 1900000000000000000;

        _mutantTypeRate[0] = 5000000000000000000;
        _mutantTypeRate[1] = 10000000000000000000;
        _mutantTypeRate[2] = 15000000000000000000;

        DEAD = address(0x000000000000000000000000000000000000dEaD);
    }

    function setContracts(address _pet, address _loot) public onlyOwner {
        pet = IERC1155(_pet);
        loot = IERC721(_loot);
        LOOT_CONTRACT = _loot;
    }

    function setBreedingContract(address _breeding) public onlyOwner {
        breeding = IERC721(_breeding);
    }

    function burnPetForMad(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public nonReentrant {
        if (!isMADExchangeOpen) {
            revert MADExchange_NotOpen();
        }
        uint256 MADtoTransfer = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            if (amounts[i] <= 0) revert MADExchange_NoTokenSendt();
            if (pet.balanceOf(_msgSender(), tokenIds[i]) < amounts[i])
                revert MADExchange_NotTheOwnerOfToken();

            MADtoTransfer += _petMADrate[tokenIds[i]] * amounts[i];
        }

        if (MADtoTransfer > mad.balanceOf(address(this))) revert MADExchange_ContractIsOutOfMAD();

        pet.safeBatchTransferFrom(_msgSender(), DEAD, tokenIds, amounts, "");

        emit BurnPets(_msgSender(), tokenIds.length);

        require(
            mad.transfer(_msgSender(), MADtoTransfer),
            "Failed to transfer MAD token"
        );
    }

    function burnLootForMad(uint256[] memory tokenIds) public nonReentrant {
        if (!isMADExchangeOpen) {
            revert MADExchange_NotOpen();
        }

        uint256 MADtoTransfer = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            if (loot.ownerOf(tokenIds[i]) != _msgSender()) revert MADExchange_NotTheOwnerOfToken();

            MADtoTransfer += _lootMADrate[
                orgStaking.getTokenYield(LOOT_CONTRACT, tokenIds[i])
            ];
            loot.safeTransferFrom(_msgSender(), DEAD, tokenIds[i]);
        }

        if (MADtoTransfer > mad.balanceOf(address(this))) revert MADExchange_ContractIsOutOfMAD();
        
        require(
            mad.transfer(_msgSender(), MADtoTransfer),
            "Failed to transfer MAD token"
        );
        emit BurnLoot(_msgSender(), tokenIds.length);
    }

    function setIsMADExchangeOpen(bool _openStatus) public onlyOwner {
        if (address(pet) == address(0)) revert MADExchange_ContractIsMissing();
        if (address(loot) == address(0)) revert MADExchange_ContractIsMissing();

        isMADExchangeOpen = _openStatus;
    }

    function setMadExchangeBreedingStatus(
        bool _mutantSaleStatus
    ) public onlyOwner {
        if (address(breeding) == address(0)) revert MADExchange_ContractIsMissing();
        mutantSalesStatus = _mutantSaleStatus;
    }

    function setMutantWallet(address _mutantwallet) public onlyOwner {
        mutantBuyerAddress = _mutantwallet;
    }

    function mutantMADPrice(uint256 tokenId) internal view returns (uint256) {
        if (tokenId < 0) return 0;

        if (tokenId <= 8000) {
            return _mutantTypeRate[0];
        } else if (tokenId <= 16000) {
            return _mutantTypeRate[1];
        } else if (tokenId <= 18000) {
            return _mutantTypeRate[1];
        } else {
            return 0;
        }
    }

    function sellMutantsForMAD(uint256[] memory tokenIds) public nonReentrant {
        if (!mutantSalesStatus) {
            revert MADExchange_MutantSellingNotOpen();
        }

        if (tokenIds.length > 50) revert MADExchange_TooManyTokens();

        uint256 MADtoTransfer = 0;
        for (uint256 i; i < tokenIds.length; i++) {
            if (breeding.ownerOf(tokenIds[i]) != _msgSender()) {
                revert MADExchange_NotTheOwnerOfToken();
            }

            MADtoTransfer += mutantMADPrice(tokenIds[i]);
        }

        if (mad.balanceOf(address(this)) < MADtoTransfer) {
            revert MADExchange_ContractIsOutOfMAD();
        }

        for (uint256 i; i < tokenIds.length; i++) {
            breeding.safeTransferFrom(
                _msgSender(),
                address(mutantBuyerAddress),
                tokenIds[i]
            );
        }

        require(
            mad.transfer(_msgSender(), MADtoTransfer),
            "Failed to transfer MAD token"
        );

        emit SellMutant(_msgSender(), tokenIds.length);
    }

    function checkMADbalance() public view returns (uint256) {
        return mad.balanceOf(address(this));
    }

    function withdrawMAD() public onlyOwner {
        if (!isMADExchangeOpen) revert MADExchange_MustBeClosed();

        uint256 _amount = checkMADbalance();
        
        require(
            mad.transfer(_msgSender(), _amount),
            "Failed to transfer MAD token"
        );

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}