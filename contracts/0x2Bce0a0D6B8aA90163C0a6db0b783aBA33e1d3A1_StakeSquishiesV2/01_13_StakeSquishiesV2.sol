// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UntransferableERC721} from "./extensions/UntransferableERC721.sol";

/**
 * MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
 * MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
 * MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
 * MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
 * MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
 * MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
 * MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
 * Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
 * KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
 * dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
 * lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
 * cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
 * cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
 * cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
 * olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
 * kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
 * XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
 * M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
 * MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
 * MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
 * MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
 * MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
 * MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
 * MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
 * MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
 * MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM
 *
 * @title StakeSquishiesV2
 * @custom:website www.squishiverse.com
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice NFT Staking contract. Staking will issue an untransferable staked token
 *         equivalent. Rewards computation will take place seperately and off-chain.
 */
contract StakeSquishiesV2 is UntransferableERC721, IERC721Receiver {
    /// @notice ERC721 contract address
    address public immutable erc721Address;

    /// @notice Track the deposit time of the token
    mapping(uint256 => uint256) public depositTimes;

    /// @notice Token non-existent
    error TokenNonExistent(uint256 tokenId);

    /// @notice Not an owner of the token
    error TokenNonOwner(uint256 tokenId);

    constructor(address _erc721Address)
        UntransferableERC721("Staked Squishiverse", "sSQUISHIE")
    {
        erc721Address = _erc721Address;
        setBaseURI("ipfs://QmQPjfDiB4PuYVo5mHVdoxnAz8XdbQ3f4NbFngWfeKnff9/");
    }

    /**
     * @notice Track deposits of an account
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account Account to query
     * @return tokenIds
     */
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /**
     * @notice Get the advanced deposits information as an array of packed byte strings
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account Account to query
     * @return depositData
     */
    function depositsOfAdvanced(address account)
        external
        view
        returns (bytes[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            bytes[] memory deposits = new bytes[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    deposits[tokenIdsIdx++] = abi.encodePacked(
                        i,
                        depositTimes[i]
                    );
                }
            }
            return deposits;
        }
    }

    /**
     * @notice Deposit tokens into the contract
     * @param tokenIds Array of token ids to stake
     */
    function deposit(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            depositTimes[tokenId] = block.timestamp;
            IERC721(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                ""
            );
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @notice Withdraw token IDs from the contract
     * @param tokenIds Array of token ids to stake
     */
    function withdraw(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (!_exists(tokenId)) {
                revert TokenNonExistent(tokenId);
            }
            if (ownerOf(tokenId) != msg.sender) {
                revert TokenNonOwner(tokenId);
            }
            _burn(tokenId);
            IERC721(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
    }

    /**
     * @dev Allows contract owner to withdraw some token from the contract
     * @param erc20Address Address of ERC20 token to withdraw
     */
    function withdrawTokens(IERC20 erc20Address) external onlyOwner {
        uint256 tokenSupply = erc20Address.balanceOf(address(this));
        erc20Address.transfer(msg.sender, tokenSupply);
    }

    /**
     * @dev Receive ERC721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}