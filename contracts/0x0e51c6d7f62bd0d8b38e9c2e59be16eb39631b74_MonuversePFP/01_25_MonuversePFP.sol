// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "erc721psi/contracts/extension/ERC721PsiBurnable.sol";
import "./ArchOfPeaceEntropy.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "fpe-map/contracts/FPEMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

                                /*░└╬┘░*\
             ░      ░█░┘────════════╩════════────└╩┘──
                ▒  ▒█ ████████████████████████████████
              ▒█  ═════════════╗░░▒▒▒▒▒░░╔═════════════
            ▒   ▒ █▒▒▒░░░░▒▒▒░░╚═════════╝░░▒▒▒░░░░░░▒
             ░ █▒  █ ███████████░░░▒▒▒░░░█████████████
                █  ░╦░     ╦╦╦ ╚█████████╝ ╦╦╦     ╦╦╦
                   │▒│░░▒▒▒│█│░▒▒▒░░ ░░▒▒▒░│█│▒▒▒░░│█│
                 ▒ │█│─────│█│─═▒░╔═╩═╗░▒══│█│═════│█│═
                   │█│░▒▒░░│█│▒░┌┘'   '╚╗░▒│█│░░▒▒░│█│
                   │▒│▒▒░ ░│█│░┌┘ \┌┴┐/ ╚╗░│█│░ ░▒▒│█│
                     │▒░┌┴░│█│░│  ┘   └┐ ║░│█│╔╩╗░▒│█│
                   │▒│▒┌┘\ │█│░│       └┐║░│█│╝/╚╗▒│█│
                 █ │█│▒│┌┘ │█│ │        │║▒│█│ └┐║▒│█│
              █ ▒  ╩╩╩▒││  ╩╩╩░│    ░   │║▒╩╩╩  │║▒╩╩╩
             ░  █ ▒███▒││ ████▒│   ░░░  │║▒████ │║▒████
           ░  ▒█ ▒██▒█▒││ ████▒│  ░░░░░ │║▒████ │║▒████
     __  __  ___ ▒█▒▒█▒││ ██▒░▒│ ░░░▒░░░│║▒████_│║▒████_____________________
    |  \/  |/ _ \█ \░▒ |│ ▒█ |\ \░░▒▒▒░░/ /__  ____/__  __ \_  ___/__  ____/
    | |\/| | | | |  \▒ |│ ░▒ | \ ░▒▒▒▒▒░ /__  __/  __  /_/ /____ \__  __/
    | |  | | |_| | |\  | \_░ |  \ ▒▒█▒▒ /__  /___  _  _, _/____/ /_  /___
    |_|  |_|\___/|_| \_|\___/    \ ███ /  /_____/  /_/ |_| /____/ /_____/
                                  \ █ /
                      ▒██ ████╗ ███████╗██████╗ 
                        ██╔══██╗██╔════╝██╔══██╗
                      ░█ █████╔╝█████╗  ██████╔╝
                         █╔═══╝ ██╔══╝  ██╔═══╝ 
                        ██║     ██║     ██║     
                        ╚*╝     ╚═/     ╚*/

/**
 * @title Monuverse PFP – Airdrop
 * @author Maxim Gaina
 *
 * @notice PFP Monuverse Airdrop Contract with
 * @notice O(1) fully decentralized and unpredictable reveal.
 */
contract MonuversePFP is ArchOfPeaceEntropy, ERC721PsiBurnable, DefaultOperatorFilterer {
    using FPEMap for uint256;
    using Strings for uint256;

    uint256 private _maxSupply;

    string private _pfpVeilURI;
    string private _pfpBaseURI;

    uint256 private constant _deterministicTokens = 4;

    constructor(
        uint256 maxSupply_,
        string memory name_,
        string memory symbol_,
        string memory archVeilURI_,
        string memory archBaseURI_,
        address vrfCoordinator_,
        bytes32 vrfGasLane_,
        uint64 vrfSubscriptionId_
    )
        ArchOfPeaceEntropy(vrfCoordinator_, vrfGasLane_, vrfSubscriptionId_)
        ERC721Psi(name_, symbol_)
    {
        _maxSupply = maxSupply_;
        _pfpVeilURI = archVeilURI_;
        _pfpBaseURI = archBaseURI_;
    }

    function airdrop(address receiver, uint256 quantity) external onlyOwner {
        require(entropy() == 0, "MonuversePFP: already revealed");
        require(_minted + quantity <= _maxSupply, "MonuversePFP: exceeding supply");

        _mint(receiver, quantity);
    }

    /**
     * @notice Reveals the entire collection when call effects are successful.
     *
     * @dev Requests a random seed that will be fulfilled in the future;
     * @dev seed will be used to randomly map token ids to metadata ids;
     * @dev callable only once in the entire Episode (i.e. collection lifecycle),
     * @dev that is, if seed is still default value and not waiting for any request;
     * @dev callable by anyone at any moment only during Reveal Chapter.
     */
    function reveal() public {
        require(entropy() == 0, "MonuversePFP: already revealed");
        require(!fulfilling(), "MonuversePFP: currently fulfilling");

        _requestRandomWord();
    }

    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "MonuversePFP: non existent token");
        require(
            _msgSender() == ownerOf(tokenId) || _msgSender() == owner(),
            "MonuversePFP: sender not token owner"
        );

        super._burn(tokenId);
    }

    /**
     * @notice Obtains mapped URI for an existing token.
     * @param tokenId existing token ID.
     *
     * @dev Pre-reveal all tokens are mapped to the same `_VeilURI`;
     * @dev post-reveal each token is unpredictably mapped to its own URI;
     * @dev post-reveal is when VRFCoordinatorV2 has successfully fulfilled random word request;
     * @dev exception are the last `_deterministicTokens` which URI are indeed, pre-decided.
     *
     * @return metadataURI token URI string
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "MonuversePFP: non existent token");

        if (entropy() == 0) {
            return _pfpVeilURI;
        } else if (tokenId > (_maxSupply - _deterministicTokens - 1)) {
            return string(abi.encodePacked(_pfpBaseURI, "/", tokenId.toString()));
        } else {
            return
                string(
                    abi.encodePacked(
                        _pfpBaseURI,
                        "/",
                        tokenId
                            .fpeMappingFeistelAuto(entropy(), _maxSupply - _deterministicTokens)
                            .toString()
                    )
                );
        }
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}