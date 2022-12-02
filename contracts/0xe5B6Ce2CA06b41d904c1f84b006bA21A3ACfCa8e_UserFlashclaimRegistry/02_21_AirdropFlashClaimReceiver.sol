// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../interfaces/IFlashClaimReceiver.sol";
import "../../dependencies/openzeppelin/contracts/Address.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";
import "../../dependencies/openzeppelin/contracts/IERC20.sol";
import "../../dependencies/openzeppelin/contracts/IERC721.sol";
import "../../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import "../../dependencies/openzeppelin/contracts/ERC721Holder.sol";
import "../../dependencies/openzeppelin/contracts/IERC1155.sol";
import "../../dependencies/openzeppelin/contracts/ERC1155Holder.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";

contract AirdropFlashClaimReceiver is
    IFlashClaimReceiver,
    ReentrancyGuard,
    Ownable,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;

    address public immutable pool;
    mapping(bytes32 => bool) public airdropClaimRecords;

    constructor(address owner_, address pool_) {
        require(owner_ != address(0), "zero owner address");
        require(pool_ != address(0), "zero pool address");

        pool = pool_;
        transferOwnership(owner_);
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     **/
    modifier onlyPool() {
        require(_msgSender() == pool, "caller must be pool");
        _;
    }

    struct ExecuteOperationLocalVars {
        uint256[] airdropTokenTypes;
        address[] airdropTokenAddresses;
        uint256[] airdropTokenIds;
        address airdropContract;
        bytes airdropParams;
        uint256 airdropBalance;
        uint256 airdropTokenId;
        bytes32 airdropKeyHash;
    }

    /**
     * @notice execute flash claim airdrop
     * @param nftAsset The NFT contract address for the airdrop
     * @param nftTokenIds The tokenids for the airdrop
     * @param params The params for the flash claim
     **/
    function executeOperation(
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external override onlyPool returns (bool) {
        require(nftTokenIds.length > 0, "empty token list");

        address initiator = owner();
        ExecuteOperationLocalVars memory vars;
        // decode parameters
        (
            vars.airdropTokenTypes,
            vars.airdropTokenAddresses,
            vars.airdropTokenIds,
            vars.airdropContract,
            vars.airdropParams
        ) = abi.decode(
            params,
            (uint256[], address[], uint256[], address, bytes)
        );

        require(
            vars.airdropTokenTypes.length > 0,
            "invalid airdrop token type"
        );
        require(
            vars.airdropTokenAddresses.length == vars.airdropTokenTypes.length,
            "invalid airdrop token address length"
        );
        require(
            vars.airdropTokenIds.length == vars.airdropTokenTypes.length,
            "invalid airdrop token id length"
        );

        require(
            vars.airdropContract != address(0),
            "invalid airdrop contract address"
        );
        require(vars.airdropParams.length >= 4, "invalid airdrop parameters");

        // allow pool transfer borrowed nfts back
        IERC721(nftAsset).setApprovalForAll(pool, true);

        // call project airdrop contract
        Address.functionCall(
            vars.airdropContract,
            vars.airdropParams,
            "call airdrop method failed"
        );

        vars.airdropKeyHash = getClaimKeyHash(
            initiator,
            nftAsset,
            nftTokenIds,
            params
        );
        airdropClaimRecords[vars.airdropKeyHash] = true;

        // transfer airdrop tokens to owner
        for (
            uint256 typeIndex = 0;
            typeIndex < vars.airdropTokenTypes.length;
            typeIndex++
        ) {
            require(
                vars.airdropTokenAddresses[typeIndex] != address(0),
                "invalid airdrop token address"
            );

            if (vars.airdropTokenTypes[typeIndex] == 1) {
                // ERC20
                vars.airdropBalance = IERC20(
                    vars.airdropTokenAddresses[typeIndex]
                ).balanceOf(address(this));
                if (vars.airdropBalance > 0) {
                    IERC20(vars.airdropTokenAddresses[typeIndex]).safeTransfer(
                        initiator,
                        vars.airdropBalance
                    );
                }
            } else if (vars.airdropTokenTypes[typeIndex] == 2) {
                // ERC721 with Enumerate
                vars.airdropBalance = IERC721(
                    vars.airdropTokenAddresses[typeIndex]
                ).balanceOf(address(this));
                for (uint256 i = 0; i < vars.airdropBalance; i++) {
                    vars.airdropTokenId = IERC721Enumerable(
                        vars.airdropTokenAddresses[typeIndex]
                    ).tokenOfOwnerByIndex(address(this), 0);
                    IERC721Enumerable(vars.airdropTokenAddresses[typeIndex])
                        .safeTransferFrom(
                            address(this),
                            initiator,
                            vars.airdropTokenId
                        );
                }
            } else if (vars.airdropTokenTypes[typeIndex] == 3) {
                // ERC1155
                vars.airdropBalance = IERC1155(
                    vars.airdropTokenAddresses[typeIndex]
                ).balanceOf(address(this), vars.airdropTokenIds[typeIndex]);
                IERC1155(vars.airdropTokenAddresses[typeIndex])
                    .safeTransferFrom(
                        address(this),
                        initiator,
                        vars.airdropTokenIds[typeIndex],
                        vars.airdropBalance,
                        new bytes(0)
                    );
            } else if (vars.airdropTokenTypes[typeIndex] == 4) {
                // ERC721 without Enumerate
                IERC721Enumerable(vars.airdropTokenAddresses[typeIndex])
                    .safeTransferFrom(
                        address(this),
                        initiator,
                        vars.airdropTokenIds[typeIndex]
                    );
            }
        }

        return true;
    }

    /**
     * @notice transfer ERC20 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being transfer
     **/
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external nonReentrant onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice transfer ERC721 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param id The tokenId being transfer
     **/
    function transferERC721(
        address token,
        address to,
        uint256 id
    ) external nonReentrant onlyOwner {
        IERC721(token).safeTransferFrom(address(this), to, id);
    }

    /**
     * @notice transfer ERC1155 Token.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param id The tokenId being transfer
     * @param amount The amount being transfer
     **/
    function transferERC1155(
        address token,
        address to,
        uint256 id,
        uint256 amount
    ) external nonReentrant onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            to,
            id,
            amount,
            new bytes(0)
        );
    }

    /**
     * @notice transfer ETH
     * @param to The address of the recipient
     * @param amount The amount being transfer
     **/
    function transferEther(address to, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @notice get claim status for a flash claim
     * @param initiator the address initiated the flash claim
     * @param nftAsset The NFT contract address for the airdrop
     * @param nftTokenIds The tokenids for the airdrop
     * @param params The params of the initiated flash claim
     **/
    function getAirdropClaimRecord(
        address initiator,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) public view returns (bool) {
        bytes32 airdropKeyHash = getClaimKeyHash(
            initiator,
            nftAsset,
            nftTokenIds,
            params
        );
        return airdropClaimRecords[airdropKeyHash];
    }

    /**
     * @notice encode flash claim param
     * @param airdropTokenTypes the airdrop reward token type
     * @param airdropTokenAddresses the airdrop reward token contract address
     * @param airdropTokenIds the airdrop reward token ids
     * @param airdropContract The address of third party airdrop contract
     * @param airdropParams The params of the flash claim
     **/
    function encodeFlashLoanParams(
        uint256[] calldata airdropTokenTypes,
        address[] calldata airdropTokenAddresses,
        uint256[] calldata airdropTokenIds,
        address airdropContract,
        bytes calldata airdropParams
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                airdropTokenTypes,
                airdropTokenAddresses,
                airdropTokenIds,
                airdropContract,
                airdropParams
            );
    }

    /**
     * @notice calculate hash for a flash claim
     * @param initiator the address initiated the flash claim
     * @param nftAsset The NFT contract address for the airdrop
     * @param nftTokenIds The tokenids for the airdrop
     * @param params The params of the initiated flash claim
     **/
    function getClaimKeyHash(
        address initiator,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(initiator, nftAsset, nftTokenIds, params));
    }
}