// SPDX-License-Identifier: MIT

/*

██╗  ██╗██╗██╗  ████████╗ ██████╗ ███╗   ██╗              
██║ ██╔╝██║██║  ╚══██╔══╝██╔═══██╗████╗  ██║              
█████╔╝ ██║██║     ██║   ██║   ██║██╔██╗ ██║              
██╔═██╗ ██║██║     ██║   ██║   ██║██║╚██╗██║              
██║  ██╗██║███████╗██║   ╚██████╔╝██║ ╚████║              
╚═╝  ╚═╝╚═╝╚══════╝╚═╝    ╚═════╝ ╚═╝  ╚═══╝              
                                                          
██████╗ ███████╗██╗    ██╗ █████╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔════╝██║    ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝█████╗  ██║ █╗ ██║███████║██████╔╝██║  ██║███████╗
██╔══██╗██╔══╝  ██║███╗██║██╔══██║██╔══██╗██║  ██║╚════██║
██║  ██║███████╗╚███╔███╔╝██║  ██║██║  ██║██████╔╝███████║
╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StaticNFT.sol";

enum RewardType {
    ERC721,
    ERC1155,
    WETH
}

struct Reward {
    address contractAddress;
    RewardType rewardType;
    uint256 token;
    uint256 amount;
}

contract KiltonRewards is Ownable, ReentrancyGuard, StaticNFT {
    using ECDSA for bytes32;
    using Strings for uint256;

    address public signer;
    address public vault;
    address public immutable kiltonAddress;

    mapping(uint256 => Reward) public rewards;

    mapping(address => uint256) public claimCounter;

    error NotAllowed();
    error InvalidSignature();

    constructor(address kilton) StaticNFT("KiltonReward", "KiltonReward") {
        kiltonAddress = kilton;
    }

    /// @dev Called by the Kilton contract to distribute rewards
    function reward(
        address recipient,
        uint256[] calldata bears,
        uint256[] calldata rewardIds,
        bytes calldata signature
    ) external nonReentrant {
        if (msg.sender != kiltonAddress) revert NotAllowed();
        checkSignature(bears, rewardIds, signature);

        if (claimCounter[recipient] == 0) {
            emit Transfer(address(0), recipient, uint160(recipient));
        }
        claimCounter[recipient] += bears.length;

        for (uint256 i = 0; i < rewardIds.length; i++) {
            uint256 id = rewardIds[i];

            Reward memory r = rewards[id];

            if (r.rewardType == RewardType.ERC1155) {
                IERC1155 c = IERC1155(r.contractAddress);
                c.safeTransferFrom(vault, recipient, r.token, r.amount, "");
            } else if (r.rewardType == RewardType.ERC721) {
                IERC721 c = IERC721(r.contractAddress);
                c.transferFrom(vault, recipient, r.token);
            } else if (r.rewardType == RewardType.WETH) {
                IERC20 c = IERC20(r.contractAddress);
                c.transferFrom(vault, recipient, r.amount);
            }
        }
    }

    /// @notice Burn a soulbound token
    function burn() external {
        if (claimCounter[msg.sender] == 0) revert NotAllowed();
        delete claimCounter[msg.sender];
        emit Transfer(msg.sender, address(0), uint160(msg.sender));
    }

    /// @notice Sets the signer wallet address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice Sets the vault wallet address
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /// @notice Sets the base URI
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    /// @notice Configure a reward
    function setupReward(
        uint256 id,
        address contractAddress,
        RewardType rewardType,
        uint256 token,
        uint256 amount
    ) external onlyOwner {
        rewards[id] = Reward(contractAddress, rewardType, token, amount);
    }

    /// @notice Configure multiple rewards
    function setupRewards(uint256[] calldata ids, Reward[] calldata _rewards)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            rewards[id] = _rewards[i];
        }
    }

    /// @dev Deletes a reward
    function deleteReward(uint256 id) external onlyOwner {
        delete rewards[id];
    }

    /// @dev Check if a signature is valid
    function checkSignature(
        uint256[] calldata bears,
        uint256[] calldata rewardIds,
        bytes calldata signature
    ) private view {
        if (
            signer !=
            ECDSA
                .toEthSignedMessageHash(
                    abi.encodePacked(bears.length, bears, rewardIds)
                )
                .recover(signature)
        ) revert InvalidSignature();
    }

    /// @dev used by StaticNFT base contract
    function getBalance(address _addr)
        internal
        view
        override
        returns (uint256)
    {
        return claimCounter[_addr] == 0 ? 0 : 1;
    }

    /// @dev used by StaticNFT base contract
    function getOwner(uint256 tokenId)
        internal
        view
        override
        returns (address)
    {
        address addr = address(uint160(tokenId));
        if (claimCounter[addr] == 0) return address(0);
        return addr;
    }

    /// @dev URI is different based on the claim counter
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        claimCounter[address(uint160(tokenId))].toString()
                    )
                )
                : "";
    }
}