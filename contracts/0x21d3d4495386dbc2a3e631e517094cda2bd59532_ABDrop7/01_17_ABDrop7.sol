//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
/**
 * @title ABDrop7
 * @author Anotherblock Technical Team
 * @notice Anotherblock NFT contract
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* Openzeppelin Contract */
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/* Custom Imports */
import {ERC721ABv2} from '../ERC721ABv2.sol';
import {IABDropManager} from '../interfaces/IABDropManager.sol';
import {ERC721ABErrors} from '../errors/ERC721ABErrors.sol';

contract ABDrop7 is ERC721ABv2, ERC721ABErrors {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Base Token URI
    string private baseTokenURI;

    /// @dev Phase definition
    Phase[4] public phasesPerDrop;

    /// @dev Stores the amounts of tokens minted per address and per phase
    mapping(address => uint256) public mintedPerAddress;

    /// @dev Anotherblock PFP NFT contract interface
    IERC721 private AB_PFP;

    bool public genesisMinted;

    /**
     * @notice
     *  Phase Structure format
     *
     * @param phaseStart : timestamp at which the phase
     * @param maxMint : maximum number of token to be minted per user during the phase
     * @param merkle : merkle tree root containing user address and associated parameters
     */
    struct Phase {
        uint256 phaseStart;
        uint256 maxMint;
        bytes32 merkle;
    }

    /// @dev Event emitted upon phase update
    event UpdatedPhase(uint256 _dropId);

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Another721 contract constructor
     *
     * @param _dropManager Anotherblock Drop Manager contract address
     * @param _abPFP season 1 PFP contract address
     * @param _baseUri base token URI
     **/
    function initialize(
        address _dropManager,
        address _abPFP,
        string memory _baseUri
    ) external initializerERC721A initializer {
        __ERC721ABv2_init(_dropManager, 'This Is Why Im Hot', 'DROP7');
        baseTokenURI = _baseUri;
        AB_PFP = IERC721(_abPFP);
        genesisMinted = false;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Let a PFP token holder mint `_quantity` token(s) of the given `_dropId`     *
     * @param _to recipient address
     * @param _quantity amount of tokens to be minted
     * @param _proof merkle tree proof used to verify whitelisted user
     */
    function mintPfpHolder(
        address _to,
        uint256 _quantity,
        bytes32[] memory _proof
    ) external payable verifyEligibility(_quantity, msg.value) {
        Phase memory phase = phasesPerDrop[0];

        // Check that the first phase has started (revert otherwise)
        if (block.timestamp < phase.phaseStart) revert SaleNotStarted();

        // Check that the user is eligible for this phase (is included in the merkle root)
        bool isWhitelisted = MerkleProof.verify(
            _proof,
            phase.merkle,
            keccak256(abi.encodePacked(_to))
        );
        if (!isWhitelisted) revert NotEligible();

        // Determine the maximum amount that can be minted by the user
        uint256 userPfpBalance = AB_PFP.balanceOf(_to);
        uint256 maxMint = phase.maxMint;
        if (userPfpBalance > 0) {
            maxMint = phase.maxMint * userPfpBalance;
        }
        // Check that user did not mint the maximum amount per address for the current phase
        if (mintedPerAddress[_to] + _quantity > maxMint)
            revert MaxMintPerAddress();

        mintedPerAddress[_to] += _quantity;
        IABDropManager(dropManager).updateDropCounter(dropId, _quantity);

        _mint(_to, _quantity);
    }

    /**
     * @notice
     *  Let a whitelisted user mint `_quantity` token(s) of the given `_dropId`
     *
     * @param _to : recipient address
     * @param _quantity : amount of tokens to be minted
     * @param _proof : merkle tree proof used to verify whitelisted user
     */
    function mintAllowlist(
        address _to,
        uint256 _quantity,
        bytes32[] memory _proof
    ) external payable verifyEligibility(_quantity, msg.value) {
        Phase memory phase = phasesPerDrop[1];

        // Check that the phase has started (revert otherwise)
        if (block.timestamp < phase.phaseStart) revert SaleNotStarted();

        bool isWhitelisted = MerkleProof.verify(
            _proof,
            phase.merkle,
            keccak256(abi.encodePacked(_to))
        );
        if (!isWhitelisted) {
            revert NotEligible();
        }

        // Determine the maximum amount that can be minted by the user
        uint256 userPfpBalance = AB_PFP.balanceOf(_to);
        uint256 maxMint = phase.maxMint;
        if (userPfpBalance > 0) {
            maxMint = phase.maxMint * userPfpBalance;
        }

        // Check that user did not mint the maximum amount per address for the current phase
        if (mintedPerAddress[_to] + _quantity > maxMint)
            revert MaxMintPerAddress();

        mintedPerAddress[_to] += _quantity;
        IABDropManager(dropManager).updateDropCounter(dropId, _quantity);

        _mint(_to, _quantity);
    }

    /**
     * @notice
     *  Let an user mint `_quantity` token(s) of the given `_dropId`
     *
     * @param _to : recipient address
     * @param _quantity : amount of tokens to be minted
     */
    function mintPublic(
        address _to,
        uint256 _quantity
    ) external payable verifyEligibility(_quantity, msg.value) {
        Phase memory phase = phasesPerDrop[2];

        // Check that the phase has started (revert otherwise)
        if (block.timestamp < phase.phaseStart) revert SaleNotStarted();

        mintedPerAddress[_to] += _quantity;
        IABDropManager(dropManager).updateDropCounter(dropId, _quantity);

        _mint(_to, _quantity);
    }

    //
    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Mint 1 token to `_anothercollector` address
     *
     * @param _anothercollector : recipient address (another collector EOA)
     */
    function mintGenesis(
        address _anothercollector
    ) external payable verifyEligibility(1, msg.value) onlyOwner {
        if (genesisMinted) revert Forbidden();
        IABDropManager(dropManager).updateDropCounter(dropId, 1);
        genesisMinted = true;

        _mint(_anothercollector, 1);
    }

    /**
     * @notice
     *  Withdraw mint proceeds to Anotherblock Treasury address
     *
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = IABDropManager(dropManager).treasury().call{
            value: address(this).balance
        }('');
        if (!success) revert TransferFailed();
    }

    /**
     * @notice
     *  Withdraw mint proceeds to the right holder address
     *
     * @param _amount : amount to be transferred
     */
    function withdrawToRightholder(uint256 _amount) external onlyOwner {
        IABDropManager.Drop memory drop = IABDropManager(dropManager).drops(
            dropId
        );
        if (drop.owner == address(0)) revert ZeroAddress();
        (bool success, ) = drop.owner.call{value: _amount}('');
        if (!success) revert TransferFailed();
    }

    /**
     * @notice
     *  Set the sale phases for drop
     *
     * @param _phases : array of phases to be set
     */
    function setDropPhases(Phase[4] memory _phases) external onlyOwner {
        phasesPerDrop[0] = _phases[0];
        phasesPerDrop[1] = _phases[1];
        phasesPerDrop[2] = _phases[2];
        phasesPerDrop[3] = _phases[3];

        emit UpdatedPhase(dropId);
    }

    /**
     * @notice
     *  Update the Base URI
     *  Only the contract owner can perform this operation
     *
     * @param _newBaseURI : new base URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Returns the base URI
     *
     * @return : base token URI state
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice
     *  Returns the starting token ID
     *
     * @return : Start token index
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //      __  ___          ___ _____
    //     /  |/  /___  ____/ (_) __(_)__  _____
    //    / /|_/ / __ \/ __  / / /_/ / _ \/ ___/
    //   / /  / / /_/ / /_/ / / __/ /  __/ /
    //  /_/  /_/\____/\__,_/_/_/ /_/\___/_/

    /**
     * @notice
     *  Ensure that the mint parameters are correct
     *
     * @param _quantity amount of tokens to be minted
     * @param _amount amount ETH sent by the caller to the contract
     */
    modifier verifyEligibility(uint256 _quantity, uint256 _amount) {
        IABDropManager.Drop memory drop = IABDropManager(dropManager).drops(
            dropId
        );

        // Check if the Drop correspond to this NFT contract
        if (drop.nft != address(this)) revert InvalidDrop();

        // Check if the drop is not sold-out
        if (drop.sold == drop.tokenInfo.supply) revert DropSoldOut();

        // Check that there are enough tokens available for sale
        if (drop.sold + _quantity > drop.tokenInfo.supply)
            revert NotEnoughTokensAvailable();

        // Check that user is sending the correct amount of ETH (will revert if user send too much or not enough)
        if (_amount != drop.tokenInfo.price * _quantity)
            revert IncorrectETHSent();
        _;
    }
}