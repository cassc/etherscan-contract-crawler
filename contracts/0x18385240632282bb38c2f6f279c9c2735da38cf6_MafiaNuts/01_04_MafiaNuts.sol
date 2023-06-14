// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**

███╗   ███╗ █████╗ ███████╗██╗ █████╗     ███╗   ██╗██╗   ██╗████████╗███████╗
████╗ ████║██╔══██╗██╔════╝██║██╔══██╗    ████╗  ██║██║   ██║╚══██╔══╝██╔════╝
██╔████╔██║███████║█████╗  ██║███████║    ██╔██╗ ██║██║   ██║   ██║   ███████╗
██║╚██╔╝██║██╔══██║██╔══╝  ██║██╔══██║    ██║╚██╗██║██║   ██║   ██║   ╚════██║
██║ ╚═╝ ██║██║  ██║██║     ██║██║  ██║    ██║ ╚████║╚██████╔╝   ██║   ███████║
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝

*/

import { ONFT721A, IERC721 } from "./layerzero/ONFT721A.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MafiaNuts smart contract. brought to you by nftperp!
 * @author n0ah <https://twitter.com/nftn0ah>
 * @author aster <https://twitter.com/aster2709>
 */
contract MafiaNuts is ONFT721A {
    enum Phase {
        INACTIVE,
        PHASE_1,
        PHASE_2,
        PUBLIC
    }

    struct PhaseInfo {
        bytes32 merkleRoot;
    }

    //
    // STORAGE
    //
    uint256 public constant MAX_SUPPLY = 1500;
    uint256 public constant JAILBREAK_SUPPLY = 224;
    uint public constant MINT_SUPPLY = MAX_SUPPLY - JAILBREAK_SUPPLY;
    string private uri;
    Phase public phase;

    mapping(Phase => PhaseInfo) public phaseInfoMap;
    mapping(address => mapping(Phase => uint)) public nutMap;

    //
    // EVENTS
    //
    event Deploy(address deployer, uint timestamp);
    event Nut(address indexed nutter, uint256 indexed tokenId, Phase indexed phase);
    event Jailbreak(address indexed nutter, uint256 indexed tokenId);
    event PhaseChange(Phase indexed phase);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _minGasToTransfer,
        address _lzEndpoint,
        address _team
    ) ONFT721A(_name, _symbol, _minGasToTransfer, _lzEndpoint) {
        _mint(_team, 277);
        emit Deploy(msg.sender, block.timestamp);
    }

    /**
     * @notice mint mafia nut
     * @param _proof merkle proof
     */
    function nut(bytes32[] calldata _proof) external {
        address nutter = msg.sender;
        uint supply = totalSupply();

        // validation
        require(phase != Phase.INACTIVE, "!active");
        require(_isNutWl(nutter, _proof), "!wl");
        require(supply < MINT_SUPPLY, "> mint supply");
        require(nutter == tx.origin, "!bot");
        uint nutCount = nutMap[nutter][phase];
        require(nutCount == 0, "nut cap");

        // mint
        _mint(nutter, 1);
        nutMap[nutter][phase] = nutCount + 1;
        emit Nut(nutter, supply + 1, phase);
    }

    /**
     * @notice mint nuts for giveaways or trading competition rewards.
     * @dev only owner
     */
    function jailbreak(address _nutter) external onlyOwner {
        uint supply = totalSupply();
        require(supply >= MINT_SUPPLY && supply < MAX_SUPPLY, "back to jail");
        _mint(_nutter, 1);
        emit Jailbreak(_nutter, supply + 1);
    }

    /**
     * @notice set active phase
     * @dev only owner
     */
    function setPhase(Phase _phase) external onlyOwner {
        phase = _phase;
        emit PhaseChange(_phase);
    }

    /**
     * @notice set phase info
     * @dev only owner
     */
    function setPhaseInfo(Phase _phase, PhaseInfo memory _phaseInfo) external onlyOwner {
        phaseInfoMap[_phase] = _phaseInfo;
    }

    /**
     * @notice set uri
     * @dev only owner
     */
    function setURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    /**
     * @notice recover stuck erc20 tokens, contact team
     * @dev only owner can call, sends tokens to owner
     */
    function recoverFT(address _token, uint _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @notice recover stuck erc721 tokens, contact team
     * @dev only owner can call, sends tokens to owner
     */
    function recoverNFT(address _token, uint _tokenId) external onlyOwner {
        IERC721(_token).transferFrom(address(this), owner(), _tokenId);
    }

    function _isNutWl(address _nutter, bytes32[] calldata _proof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_nutter));
        bytes32 root = phaseInfoMap[phase].merkleRoot;
        if (root == bytes32(0)) return true;
        return MerkleProof.verify(_proof, root, leaf);
    }

    //
    // OVERRIDES
    //
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}