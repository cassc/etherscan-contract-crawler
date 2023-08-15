// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.18;

//                                 __...----..
//                              .-'           `-.
//                             /        .---.._  \
//                             |        |   \  \ |
//                              `.      |    | | |        _____
//                                `     '    | | /    _.-`      `.
//                                 \    |  .'| //'''.'            \
//                                  `---'_(`.||.`.`.'    _.`.'''-. \
//                                     _(`'.    `.`.`'.-'  \\     \ \
//                                    (' .'   `-._.- /      \\     \ |
//                                   ('./   `-._   .-|       \\     ||
//                                   ('.\ | | 0') ('0 __.--.  \`----'/
//                              _.--('..|   `--    .'  .-.  `. `--..'
//                _..--..._ _.-'    ('.:|      .  /   ` 0 `   \
//             .'         .-'        `..'  |  / .^.           |
//            /         .'                 \ '  .             `._
//         .'|                              `.  \`...____.----._.'
//       .'.'|         .                      \ |    |_||_||__|
//      //   \         |                  _.-'| |_ `.   \
//      ||   |         |                     /\ \_| _  _ |
//      ||   |         /.     .              ' `.`.| || ||
//      ||   /        ' '     |        .     |   `.`---'/
//    .' `.  |       .' .'`.   \     .'     /      `...'
//  .'     \  \    .'.'     `---\    '.-'   |
// )/\ / /)/ .|    \             `.   `.\   \
//  )/ \(   /  \   |               \   | `.  `-.
//   )/     )   |  |             __ \   \.-`    \
//          |  /|  )  .-.      //' `-|   \  _   /
//         / _| |  `-'.-.\     ||    `.   )_.--'
//         )  \ '-.  /  '|     ''.__.-`\  |
//        /  `-\  '._|--'               \  `.
//        \    _\                       /    `---.
//        /.--`  \                      \    .''''\
//        `._..._|                       `-.'  .-. |
//                                        '_.'-./.'
//
// Curra first logo was a donkey. But we decided that it's not a good idea to have a donkey as a logo, so let just keep it here...

import {ERC721} from "lib/solmate/src/tokens/ERC721.sol";
import {Owned} from "lib/solmate/src/auth/Owned.sol";

import {ERC1967Factory} from "./ERC1967Factory.sol";
import {Forwarder} from "./Forwarder.sol";

/// @author pintak.eth
/// @title Entry point contract to Curra protocol
contract Curra is ERC1967Factory, ERC721, Owned {
    error NotATokenOwner();

    event ProxyDeployed(uint256 ownershipId, address proxyAddress);

    string public baseURI;

    constructor() ERC721("Curra Ownerships", "CRO") Owned(msg.sender) {
        baseURI = "https://curra.io/ownerships/";
    }

    function setBaseURI(string calldata value) external onlyOwner {
        baseURI = value;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, id));
    }

    /// @notice Used to mint new ownerships
    /// @param recipient - address to mint ownership to
    function mint(address recipient, bytes32 salt) external returns (uint256 id) {
        bytes32 s = keccak256(abi.encodePacked(recipient, salt));
        id = uint256(s);
        _safeMint(recipient, id);
    }

    modifier onlyTokenOwner(uint256 ownershipId) {
        if (ownerOf(ownershipId) != msg.sender) {
            revert NotATokenOwner();
        }
        _;
    }

    /// @notice Used to upgrade rule by ownership NFT owner
    /// @param ownershipId - id of ownership NFT
    /// @param implementation - new rule implementation address
    function upgradeRule(uint256 ownershipId, address implementation) public onlyTokenOwner(ownershipId) {
        address proxyAddress = predictProxyAddress(ownershipId);
        upgrade(proxyAddress, implementation);
    }

    function predictProxyAddress(uint256 ownershipId) public view returns (address proxyAddress) {
        bytes32 salt = bytes32(ownershipId);
        proxyAddress = predictDeterministicAddress(salt);
    }

    function deployProxy(uint256 ownershipId, address implementation) public returns (address proxy) {
        bytes32 salt = bytes32(ownershipId);
        proxy = deploy(implementation, address(this), salt, true, _emptyData());
        emit ProxyDeployed(ownershipId, proxy);
    }
}