// Squishiland by Squishiverse (www.squishiland.com) - Staking Contract

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdlod0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'....,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMWKxc'..;cll:,..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWXkc'..,cldddddol;'..,lOXWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMWXkl,..,:lddoodoooooool:'..;oOXWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXOl,..';lodddooodddollloodol;...;o0NWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMWNOl,..';cloddddxxxxxddollodddddoc:,...;o0NWMMMMMMMMMMMMM
// MMMMMMMMMMMNOo;..';coooodxxxxxkkxdddoodxxxddddooolc;...:d0NMMMMMMMMMMM
// MMMMMMMMN0o;...;coddddddxxxxxddddddddxkOkkxdxxxxddddo:,...:xKNMMMMMMMM
// MMMMMN0d:...;lodddddxxxxxxxxdddxxxddxkkkxxxxdxxxxxxddolc;'..'cxKWMMMMM
// MMN0d:'..,:odxxddddxxkOOkxxxddodxxxxdddddddddxxxxxddollllol:,..'cxKWMM
// Kd:'..,:coodddddddxxxkkkkxxxddoodddddxxxxxdxkOO00kdolllloooool:,..'ckX
// :..';cooooodddddddddddddddddddoooooddxxxxxxxxk00Okddoolloooodddol:'..l
// '..:cloooooddddddddddddddddxxdddoooooddddddxxxxxxdoooooddddddollcl;..:
// ;..',;coddddddddddddddddxxxdddddddddddoooddxxxxxdolllloooooooolc::,..c
// c....',;clooooddddddddxxxxxddddddddddddddddddxxxollllllllclllcc;;;'..o
// o.......';::cldddddddxxxxxxxdddddddddddddddddooolllooooolc:::;;,,,'..d
// x. .......'',:loddddddddddddddxkkxddddddddddddollloooolc:,;,,,''',. .x
// k. ..........',;clooooooddddddxO0Okkxddoooddddoolcccc:;,''''''''''..'O
// O' .............',;;:clloddddxkOOkkkxooooollllool:;,,,''''''''.'''..;0
// O,..................';:cloodddxxdooollooooolccccc:,''',,,,'''.......:K
// 0;...................',,;:clddooloddoloddolc::::;,,''',,,''.........lX
// 0:......................'',;clooodxxdolllc:;,,,,,'''''''''..........dN
// Kc. .......................',,:coxxddl:;;,,''''''',,,''.'......... .xN
// Xo. .........................',;:loll:;,''''''''',,,''............ 'kW
// Nd. ...........................',;:::;,,,,'',,,''',''............. 'OW
// Wk' ............................',;;;,,,;,'',,,'''''.............. 'OM
// M0;. ............ ..............',,,;;;,,'''''''...................;0M
// MNk;.  ..........................',,;;,''''''''...................:OWM
// MMWXOl'.  ............ ..........',,,,''''''''.................,lONWMM
// MMMMMWKx:.. .....................',,,,''...'''..............'ckXWMMMMM
// MMMMMMMMNOo,.  ..................',,,''...................,d0NMMMMMMMM
// MMMMMMMMMMWKkc..  ...............'',''.................'lkXWMMMMMMMMMM
// MMMMMMMMMMMMMW0o,.  ..............'''................;dKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWXkc'.  ...........................,lONWMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0d;.   ......................:xXWMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMWXkc'.  ........''.......,o0NMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWKx:.. ............'ckXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMNOo,..........;d0NMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc'....'lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOocld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

// Development help from @lozzereth (www.allthingsweb3.com)

// SPDX-License-Identifier: CC-BY-NC-4.0

pragma solidity ^0.8.13;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {UntransferableERC721} from "./extensions/UntransferableERC721.sol";
import {ISquishiland} from "./ISquishiland.sol";

/**
 * @title StakeLands
 * @author @lozzereth (www.allthingsweb3.com)
 * @notice NFT Staking contract. Staking will issue an untransferable staked token
 *         equivalent. Rewards computation will take place seperately and off-chain.
 */
contract StakeLands is UntransferableERC721, IERC721Receiver {
    /// @notice Contract addresses
    ISquishiland public immutable erc721Address;

    /// @notice Track the deposit time of an NFT
    mapping(uint256 => uint256) public depositTimes;

    /// @notice Not an owner of the NFT
    error TokenNonOwner(uint256 tokenId);

    constructor(ISquishiland _erc721Address)
        UntransferableERC721("Staked Squishiland", "sSVLAND")
    {
        erc721Address = _erc721Address;
    }

    /**
     * @notice Track deposits of an account
     * @dev Intended for off-chain computation having O(totalSupply) complexity
     * @param account - Account to query
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
     * @param account - Account to query
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
     * @notice Deposit Squishies into the contract
     * @param tokenIds - Array of token ids to stake
     */
    function deposit(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            depositTimes[tokenId] = block.timestamp;
            ISquishiland(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                ""
            );
            _mint(msg.sender, tokenId);
        }
    }

    /**
     * @notice Withdraw Squishies from the contract
     * @param tokenIds - Array of token ids to stake
     */
    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != msg.sender) {
                revert TokenNonOwner(tokenId);
            }
            _burn(tokenId);
            ISquishiland(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                ""
            );
        }
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