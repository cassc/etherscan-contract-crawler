// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { Owned } from "../dependencies/solmate/Owned.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { ERC721Holder } from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "../base/EIP712.sol";

/**
 * @title CyberVault
 * @author CyberConnect
 * @notice This contract is used to create CyberVault.
 */
contract CyberVault is
    Initializable,
    Owned,
    ReentrancyGuard,
    EIP712,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;

    event Initialize(address indexed owner);
    event Claim(
        string profileId,
        address indexed to,
        address indexed currency,
        uint256 amount
    );
    event Claim721(
        string profileId,
        address indexed to,
        address indexed currency,
        uint256 tokenId
    );
    event Claim1155(
        string profileId,
        address indexed to,
        address indexed currency,
        uint256 tokenId,
        uint256 amount
    );
    event Deposit(
        string profileId,
        address indexed currency,
        uint256 indexed amount
    );
    event Deposit721(
        string profileId,
        address indexed currency,
        uint256 indexed tokenId
    );
    event Deposit1155(
        string profileId,
        address indexed currency,
        uint256 indexed tokenId,
        uint256 indexed amount
    );
    event SetSigner(address indexed preSigner, address indexed newSigner);

    address internal _signer;
    mapping(address => int256) public nonces;
    mapping(string => mapping(address => uint256)) _balanceByProfileByCurrency;
    mapping(string => mapping(address => mapping(uint256 => uint256))) _balanceByProfileByCurrencyByTokenID;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address owner) initializer {
        _signer = owner;
        Owned.__Owned_Init(owner);
        ReentrancyGuard.__ReentrancyGuard_init();
        emit Initialize(owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claims ERC20 tokens from a profile's deposit.
     *
     * @param profileId The profile id.
     * @param to The claimer address.
     * @param currency The ERC20 address.
     * @param amount The amount to claim.
     * @param sig The EIP712 signature.
     */
    function claim(
        string calldata profileId,
        address to,
        address currency,
        uint256 amount,
        DataTypes.EIP712Signature calldata sig
    ) external nonReentrant {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM_TYPEHASH,
                        keccak256(bytes(profileId)),
                        to,
                        currency,
                        amount,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        require(
            _balanceByProfileByCurrency[profileId][currency] >= amount,
            "INSUFFICIENT_BALANCE"
        );

        _balanceByProfileByCurrency[profileId][currency] -= amount;

        IERC20(currency).safeTransfer(to, amount);
        emit Claim(profileId, to, currency, amount);
    }

    /**
     * @notice Claims ERC721 tokens from a profile's deposit.
     *
     * @param profileId The profile id.
     * @param to The claimer address.
     * @param currency The ERC721 address.
     * @param tokenId The tokenId to claim.
     * @param sig The EIP712 signature.
     */
    function claim721(
        string calldata profileId,
        address to,
        address currency,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external nonReentrant {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM721_TYPEHASH,
                        keccak256(bytes(profileId)),
                        to,
                        currency,
                        tokenId,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        require(
            _balanceByProfileByCurrencyByTokenID[profileId][currency][
                tokenId
            ] == 1,
            "INSUFFICIENT_BALANCE"
        );

        _balanceByProfileByCurrencyByTokenID[profileId][currency][tokenId] = 0;

        IERC721(currency).safeTransferFrom(address(this), to, tokenId);
        emit Claim721(profileId, to, currency, tokenId);
    }

    /**
     * @notice Claims ERC1155 tokens from a profile's deposit.
     *
     * @param profileId The profile id.
     * @param to The claimer address.
     * @param currency The ERC1155 address.
     * @param tokenId The tokenId to claim.
     * @param amount The amount to claim.
     * @param sig The EIP712 signature.
     */
    function claim1155(
        string calldata profileId,
        address to,
        address currency,
        uint256 tokenId,
        uint256 amount,
        DataTypes.EIP712Signature calldata sig
    ) external nonReentrant {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._CLAIM1155_TYPEHASH,
                        keccak256(bytes(profileId)),
                        to,
                        currency,
                        tokenId,
                        amount,
                        nonces[to]++,
                        sig.deadline
                    )
                )
            ),
            _signer,
            sig
        );

        require(
            _balanceByProfileByCurrencyByTokenID[profileId][currency][
                tokenId
            ] >= amount,
            "INSUFFICIENT_BALANCE"
        );

        _balanceByProfileByCurrencyByTokenID[profileId][currency][
            tokenId
        ] -= amount;

        IERC1155(currency).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            ""
        );
        emit Claim1155(profileId, to, currency, tokenId, amount);
    }

    /**
     * @notice Deposit ERC20 tokens to a profile's balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC20 address.
     * @param amount The amount to deposit.
     */
    function deposit(
        string calldata profileId,
        address currency,
        uint256 amount
    ) external nonReentrant {
        require(
            IERC20(currency).balanceOf(msg.sender) >= amount,
            "INSUFFICIENT_BALANCE"
        );
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);

        _balanceByProfileByCurrency[profileId][currency] += amount;
        emit Deposit(profileId, currency, amount);
    }

    /**
     * @notice Deposit ERC721 tokens to a profile's balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC721 address.
     * @param tokenId The tokenId to deposit.
     */
    function deposit721(
        string calldata profileId,
        address currency,
        uint256 tokenId
    ) external nonReentrant {
        require(
            IERC721(currency).ownerOf(tokenId) == msg.sender,
            "NOT_NFT_OWNER"
        );
        IERC721(currency).safeTransferFrom(msg.sender, address(this), tokenId);

        _balanceByProfileByCurrencyByTokenID[profileId][currency][tokenId] = 1;
        emit Deposit721(profileId, currency, tokenId);
    }

    /**
     * @notice Deposit ERC1155 tokens to a profile's balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC1155 address.
     * @param tokenId The tokenId to deposit.
     * @param amount The amount to deposit.
     */
    function deposit1155(
        string calldata profileId,
        address currency,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant {
        require(
            IERC1155(currency).balanceOf(msg.sender, tokenId) >= amount,
            "INSUFFICIENT_NFT_BALANCE"
        );
        IERC1155(currency).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );

        _balanceByProfileByCurrencyByTokenID[profileId][currency][
            tokenId
        ] += amount;
        emit Deposit1155(profileId, currency, tokenId, amount);
    }

    /**
     * @notice Sets the new signer address.
     *
     * @param signer The signer address.
     * @dev The address can not be zero address.
     */
    function setSigner(address signer) external onlyOwner {
        require(signer != address(0), "zero address signer");
        address preSigner = _signer;
        _signer = signer;

        emit SetSigner(preSigner, signer);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the signer address.
     *
     * @return address The signer address.
     */
    function getSigner() external view returns (address) {
        return _signer;
    }

    /**
     * @notice Gets the balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC20 currency address.
     */
    function balanceOf(string calldata profileId, address currency)
        external
        view
        returns (uint256)
    {
        return _balanceByProfileByCurrency[profileId][currency];
    }

    /**
     * @notice Gets the nft balance.
     *
     * @param profileId The profile id.
     * @param currency The ERC20 currency address.
     */
    function nftBalanceOf(
        string calldata profileId,
        address currency,
        uint256 tokenId
    ) external view returns (uint256) {
        return
            _balanceByProfileByCurrencyByTokenID[profileId][currency][tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _domainSeparatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return "CyberVault";
    }
}