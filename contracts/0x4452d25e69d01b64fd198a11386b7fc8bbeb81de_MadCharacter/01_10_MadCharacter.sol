// SPDX-License-Identifier: MIT
//
//  ███████████  █████         █████████     █████████  █████   ████ █████       ██████████ ██████   ██████    ███████    ██████   █████
// ░░███░░░░░███░░███         ███░░░░░███   ███░░░░░███░░███   ███░ ░░███       ░░███░░░░░█░░██████ ██████   ███░░░░░███ ░░██████ ░░███
//  ░███    ░███ ░███        ░███    ░███  ███     ░░░  ░███  ███    ░███        ░███  █ ░  ░███░█████░███  ███     ░░███ ░███░███ ░███
//  ░██████████  ░███        ░███████████ ░███          ░███████     ░███        ░██████    ░███░░███ ░███ ░███      ░███ ░███░░███░███
//  ░███░░░░░███ ░███        ░███░░░░░███ ░███          ░███░░███    ░███        ░███░░█    ░███ ░░░  ░███ ░███      ░███ ░███ ░░██████
//  ░███    ░███ ░███      █ ░███    ░███ ░░███     ███ ░███ ░░███   ░███      █ ░███ ░   █ ░███      ░███ ░░███     ███  ░███  ░░█████
//  ███████████  ███████████ █████   █████ ░░█████████  █████ ░░████ ███████████ ██████████ █████     █████ ░░░███████░   █████  ░░█████
// ░░░░░░░░░░░  ░░░░░░░░░░░ ░░░░░   ░░░░░   ░░░░░░░░░  ░░░░░   ░░░░ ░░░░░░░░░░░ ░░░░░░░░░░ ░░░░░     ░░░░░    ░░░░░░░    ░░░░░    ░░░░░
//
// BLACKLEMON: https://github.com/BlackLemon-wtf
// =======================================================================================================================================
//
//    █████████    █████████   ██████████   ██████   ██████    ███████     █████████     █████    ███████
//   ███░░░░░███  ███░░░░░███ ░░███░░░░███ ░░██████ ██████   ███░░░░░███  ███░░░░░███   ░░███   ███░░░░░███
//  ███     ░░░  ░███    ░███  ░███   ░░███ ░███░█████░███  ███     ░░███░███    ░░░     ░███  ███     ░░███
// ░███          ░███████████  ░███    ░███ ░███░░███ ░███ ░███      ░███░░█████████     ░███ ░███      ░███
// ░███          ░███░░░░░███  ░███    ░███ ░███ ░░░  ░███ ░███      ░███ ░░░░░░░░███    ░███ ░███      ░███
// ░░███     ███ ░███    ░███  ░███    ███  ░███      ░███ ░░███     ███  ███    ░███    ░███ ░░███     ███
//  ░░█████████  █████   █████ ██████████   █████     █████ ░░░███████░  ░░█████████  ██ █████ ░░░███████░
//   ░░░░░░░░░  ░░░░░   ░░░░░ ░░░░░░░░░░   ░░░░░     ░░░░░    ░░░░░░░     ░░░░░░░░░  ░░ ░░░░░    ░░░░░░░
//
// CADMOS.IO: https://github.com/CADMOS-SAL
// ==========================================================================================================
// ================================================  MadCharacter  ==========================================
// ==========================================================================================================

pragma solidity 0.8.7;

import "./IMadPass.sol";
import "./IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract MadCharacter is ERC721A, Ownable {
    /* ========== CONSTANTS ========== */

    uint256 private constant wad = 1e18;
    uint256 private constant COUNT = 7777;
    address private immutable MADPASS;
    uint256 private constant IDMADPASSNORMAL = 1;
    uint256 private constant IDMADPASSTEAM = 2;
    IOperatorFilterRegistry constant operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E); //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol

    /* ========== STATE VARIABLES ========== */
    bool public FOLLOWOZREGISTRY = true; //apply OZ blacklist
    bool public canMint;
    string public baseURI;
    bool public canChangeURI = true;
    mapping(address => bool) private _frozen;
    mapping(uint256 => uint256) private _lastTransfer;
    uint256 public allLastTransfers;
    uint256 public mintStartDate;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _MADPASS,
        address teamAddress
    ) ERC721A(_name, _symbol) {
        baseURI = _baseUri;
        MADPASS = _MADPASS;
        _mintTeam(_MADPASS, teamAddress);
        if (address(operatorFilterRegistry).code.length > 0) { //to not revert in test env
            operatorFilterRegistry.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6); //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol
        }
    }

    /* ========== VIEWS ========== */

    /// @notice Returns last transfer timestamp of the NFT
    function lastTransfer(uint256 tokenid) public view returns (uint256) {
        uint256 effLastTransfer = _lastTransfer[tokenid];
        effLastTransfer = effLastTransfer == 0
            ? mintStartDate
            : effLastTransfer;
        return effLastTransfer;
    }

    /// @notice Returns how long the NFT has been hodled (timestamp)
    /// @notice Before startMint has been called, it returns the Unix Time
    /// @notice hodlingPeriod is resetted after each transfer
    function hodlingPeriod(uint256 tokenid) external view returns (uint256) {
        uint256 effLastTransfer = lastTransfer(tokenid);
        return block.timestamp - effLastTransfer;
    }

    /// @notice Returns the relative hodling share of the NFT with regards to all other NFTS. Expressed in wad (100% =1e18)
    function hodlingShare(uint256 tokenid) external view returns (uint256) {
        uint256 effLastTransfer = lastTransfer(tokenid);
        uint256 AverageLastTransfer_ = allLastTransfers / COUNT;
        return
            (wad * (block.timestamp - effLastTransfer)) /
            (block.timestamp - AverageLastTransfer_) /
            COUNT;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _isAllowedOperator(address from) internal view returns (bool isAllowed) {
        if(_frozen[from]) {
            return false;
        }
        else{ //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol
        // Check registry code length to facilitate testing in environments without a deployed registry.
            if (address(operatorFilterRegistry).code.length > 0 && FOLLOWOZREGISTRY) {
                // Allow spending tokens from addresses with balance
                // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
                // from an EOA.
                if (from == msg.sender) {
                    return true;
                }
                isAllowed = (operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                            && operatorFilterRegistry.isOperatorAllowed(address(this), from));
                return isAllowed;
            }
            else{
                return true;
            }
        }
        
    }


    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        require(_isAllowedOperator(from) && _isAllowedOperator(to), "MADCHARACTER: frozen");
        if (from != address(0)) {
            // if not mint
            uint256 lastTransfer_ = lastTransfer(startTokenId);
            _lastTransfer[startTokenId] = block.timestamp;
            uint256 allLastTransfers_ = allLastTransfers;
            allLastTransfers =
                allLastTransfers_ +
                block.timestamp -
                lastTransfer_;
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _mintTeam(address _MADPASS, address teamAddress) internal {
        uint256 amount = IMadPass(_MADPASS).balanceOf(
            teamAddress,
            IDMADPASSTEAM
        );
        if(amount>0){
            IMadPass(_MADPASS).burn(teamAddress, IDMADPASSTEAM, amount);
            _safeMint(teamAddress, amount);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Mint amount Madz Characters - amounts of MadPass will be burned from msg.sender wallet
    /// @dev the mint function has been modified to burn an ERC1155 after approving it to the ERC721
    function mint(uint256 amount) external {
        require(canMint, "Minting did not start");
        IMadPass(MADPASS).burn(msg.sender, IDMADPASSNORMAL, amount);
        _safeMint(msg.sender, amount);
    }

    /// @notice Get Token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    //true iff we want to apply OZ blacklist
    function followOZRegistry(bool status) external onlyOwner {
        FOLLOWOZREGISTRY = status;
    }


    /// @notice Allow people to Mint
    function startMint() external onlyOwner {
        canMint = true;
        mintStartDate = block.timestamp;
        allLastTransfers = block.timestamp * COUNT;
        emit StartMint();
    }

    /// @notice Admin changes URI
    function setURI(string memory newuri) external onlyOwner {
        require(canChangeURI, "Resetting of URI has been renounced by Admin");
        baseURI = newuri;
        emit SetURI(newuri);
    }

    /// @notice Admin renounces the right to change URI
    function renounceChangeURI() external onlyOwner {
        canChangeURI = false;
        emit RenounceChangeURI();
    }

    /// @notice Freezes the tokens of an address
    function freezeAccount(address to) external onlyOwner {
        _frozen[to] = true;
        emit FreezeAccount(to);
    }

    /// @notice UnFreezes the tokens of an address
    function unFreezeAccount(address to) external onlyOwner {
        _frozen[to] = false;
        emit UnFreezeAccount(to);
    }

    /* ========== EVENTS ========== */

    /// @dev All the following events are emitted during Admin functions call
    event StartMint();
    event SetURI(string indexed uri);
    event RenounceChangeURI();
    event FreezeAccount(address indexed accountAddress);
    event UnFreezeAccount(address indexed accountAddress);
}