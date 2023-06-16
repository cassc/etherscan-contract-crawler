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
// ==================================================  MadPass  =============================================
// ==========================================================================================================

pragma solidity 0.8.7;

import "./IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MadPass is ERC1155, Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    string public name;
    string public symbol;
    uint256 private constant MAX_SUPPLY_TEAM = 0;
    uint256 private constant MAX_SUPPLY_OG = 3315 - MAX_SUPPLY_TEAM;
    uint256 private constant MAX_SUPPLY_NORMAL = 4462;
    uint256 private constant MAX_MINT_USER = 2;
    uint256 private constant MAX_MINT_OG = 200;
    address private immutable signingAdrress;
    enum MintMode {
        NormalUser,
        OGUser
    }
    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E); //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol

    /* ========== STATE VARIABLES ========== */
    bool public FOLLOWOZREGISTRY = true; //apply OZ blacklist
    bool public canMint;
    uint256 public mintPrice;
    uint256 public mintedNumberNormal;
    uint256 public mintedNumberOG;
    uint256 public mintedNumberTeam;
    bool public canChangeURI = true;
    bool public canChangeMadCharacterAddress = true;
    address private _madCharacterAddress;
    mapping(address => uint256) private mintedbyAddress;
    mapping(address => bool) private _frozen; //True if the balance of frozen[address] is frozen (no transfer)

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory uri_,
        string memory _name,
        string memory _symbol,
        address _signingAdrress,
        uint256 _mintPrice
    ) ERC1155(uri_) {
        name = _name;
        symbol = _symbol;
        signingAdrress = _signingAdrress;
        mintPrice = _mintPrice;
        _mintTeam(msg.sender);
        if (address(operatorFilterRegistry).code.length > 0) {
            //to not revert in test env
            operatorFilterRegistry.registerAndSubscribe(
                address(this),
                0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
            ); //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol
        }
    }

    /* ========== VIEWS ========== */

    function totalSupply() public view returns (uint256) {
        return mintedNumberNormal + mintedNumberOG + mintedNumberTeam;
    }

    function _chainID() private view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return chainID;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _isAllowedOperator(address from)
        internal
        view
        returns (bool isAllowed)
    {
        if (_frozen[from]) {
            return false;
        } else {
            //https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol
            // Check registry code length to facilitate testing in environments without a deployed registry.
            if (
                address(operatorFilterRegistry).code.length > 0 &&
                FOLLOWOZREGISTRY
            ) {
                // Allow spending tokens from addresses with balance
                // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
                // from an EOA.
                if (from == msg.sender) {
                    return true;
                }
                isAllowed = (operatorFilterRegistry.isOperatorAllowed(
                    address(this),
                    msg.sender
                ) &&
                    operatorFilterRegistry.isOperatorAllowed(
                        address(this),
                        from
                    ));
                return isAllowed;
            } else {
                return true;
            }
        }
    }

    function _checksignature(
        bytes memory signature,
        address minter,
        uint256 mintLimit,
        uint8 mintMode
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                minter,
                mintLimit,
                mintMode,
                _chainID(),
                address(this)
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(signature);
        require(signer == signingAdrress, "Signer address mismatch.");
    }

    /// @dev Override: Token Freeze
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        require(
            _isAllowedOperator(from) && _isAllowedOperator(to),
            "MADPASS: frozen"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mintTeam(address teamAddress) internal {
        mintedNumberTeam = MAX_SUPPLY_TEAM;
        if(mintedNumberTeam>0){
            _mint(teamAddress, 2, MAX_SUPPLY_TEAM, "0x0");
            emit TeamMint(teamAddress, MAX_SUPPLY_TEAM);
        }
    }

    /// @notice Mint amount Madz Pass - Caller need to pay mintPrice x amounts and add a valid signature
    function _mintBatchNormalUser(
        address recipient,
        uint256 amounts,
        bytes calldata signature
    ) internal {
        require(canMint, "Minting did not start");
        uint256 mintedUser_ = mintedbyAddress[recipient];
        mintedUser_ += amounts;
        mintedbyAddress[recipient] = mintedUser_;
        uint256 mintedNumberNormal_ = mintedNumberNormal;
        mintedNumberNormal_ += amounts;
        mintedNumberNormal = mintedNumberNormal_;
        require(amounts > 0, "MADPASS: Nil mint");
        require(
            mintedNumberNormal_ <= MAX_SUPPLY_NORMAL,
            "MADPASS: All the normal passes have already been minted"
        );
        require(
            mintedUser_ <= MAX_MINT_USER,
            "MADPASS: User Mint Allowance Exceeded"
        );
        require(msg.value == mintPrice * amounts, "MADPASS: Mint Price");
        _checksignature(
            signature,
            recipient,
            MAX_MINT_USER,
            uint8(MintMode.NormalUser)
        );
        _mint(recipient, 1, amounts, "0x0");
        emit NormalMint(recipient, amounts);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    receive() external payable {}

    /// @notice Mint amount Madz Pass for another user- Caller need to pay mintPrice x amounts and add a valid signature
    function mintBatchNormalUserDelegated(
        address recipient,
        uint256 amounts,
        bytes calldata signature
    ) external payable {
        _mintBatchNormalUser(recipient, amounts, signature);
    }

    /// @notice Mint amount Madz Pass - Caller need to pay mintPrice x amounts and add a valid signature
    function mintBatchNormalUser(uint256 amounts, bytes calldata signature)
        external
        payable
    {
        _mintBatchNormalUser(msg.sender, amounts, signature);
    }

    /// @notice Mint amount Madz Pass for OG - Caller need to add a valid signature
    function mintBatchNormalOG(
        uint256 amounts,
        uint256 mintLimit,
        bytes calldata signature
    ) external {
        require(canMint, "Minting did not start");
        uint256 mintedUser_ = mintedbyAddress[msg.sender];
        mintedUser_ += amounts;
        mintedbyAddress[msg.sender] = mintedUser_;
        uint256 mintedNumberOG_ = mintedNumberOG;
        mintedNumberOG_ += amounts;
        mintedNumberOG = mintedNumberOG_;
        require(amounts > 0, "MADPASS: Nil mint");
        require(
            mintedNumberOG_ <= MAX_SUPPLY_OG,
            "MADPASS: All the normal passes have already been minted"
        );
        require(
            mintedUser_ <= mintLimit,
            "MADPASS: User Mint Allowance Exceeded"
        );
        require(
            mintLimit <= MAX_MINT_OG,
            "MADPASS: User Mint Allowance Exceeded"
        );
        _checksignature(
            signature,
            msg.sender,
            mintLimit,
            uint8(MintMode.OGUser)
        );
        _mint(msg.sender, 1, amounts, "0x0");
        emit OGMint(msg.sender, amounts);
    }

    /// @notice Burn amount Pass #id of 'from'.
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(
            from == msg.sender || msg.sender == _madCharacterAddress,
            "Account is neither owner nor approved"
        );
        _burn(from, id, amount);
    }

    /// @notice Get Token URI
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    super.uri(_tokenId),
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    //true iff we want to apply OZ blacklist
    function followOZRegistry(bool status) external onlyOwner {
        FOLLOWOZREGISTRY = status;
    }

    /// @notice Allow people to Mint
    function startMint() public onlyOwner {
        canMint = true;
        emit StartMint();
    }

    /// @notice Allows Admin to withdraw ETH
    function withdrawETH() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
        emit WithdrawETH(address(this).balance);
    }

    /// @notice Allows Admin to withdraw token amount
    function withdrawToken(uint256 amount, address tokenAddress)
        external
        onlyOwner
    {
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit WithdrawERC20(tokenAddress, amount);
    }

    /// @notice Admin changes URI
    function setURI(string memory newuri) external onlyOwner {
        require(canChangeURI, "Resetting of URI has been renounced by Admin");
        _setURI(newuri);
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

    /// @notice Admin sets mintPrice
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
        emit SetMintPrice(newMintPrice);
    }

    /// @notice Admin sets _madCharacterAddress (which has the right to burn Passes)
    function setMadCharacterAddress(address preComputedMadCharacter)
        external
        onlyOwner
    {
        require(
            canChangeMadCharacterAddress,
            "Resetting of MadCharacterAddress has been renounced by Admin"
        );
        _madCharacterAddress = preComputedMadCharacter;
    }

    /// @notice Admin renounces the right to change _madCharacterAddress
    function renounceChangeMadCharacterAddress() external onlyOwner {
        canChangeMadCharacterAddress = false;
        emit RenounceChangeMadCharacterAddress();
    }

    /* ========== EVENTS ========== */

    /// @dev Emitted during a call to mintBatchNormalOG
    /// OGMint is the most important event because it will be used to aggregate
    /// data off-chain allowing the vesting admin to then manually distribute
    /// the passes to the OGs who decided to mint some of them.
    event OGMint(address indexed OGAddress, uint256 amount);

    /// @dev Emitted during a call to mintBatchNormalUser
    event NormalMint(address indexed NormalUserAddress, uint256 amount);

    /// @dev Emitted during a call to mintBatchTeam
    event TeamMint(address indexed TeamUserAddress, uint256 amount);

    /// @dev All the following events are emitted during Admin functions call
    event StartMint();
    event WithdrawETH(uint256 value);
    event WithdrawERC20(address indexed tokenAddress, uint256 amount);
    event SetURI(string indexed uri);
    event RenounceChangeURI();
    event RenounceChangeMadCharacterAddress();
    event FreezeAccount(address indexed accountAddress);
    event UnFreezeAccount(address indexed accountAddress);
    event SetMintPrice(uint256 indexed mintprice);
}