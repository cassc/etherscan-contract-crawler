// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2; // required to accept structs as function parameters

import "./ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IBurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BloodOfMolochClaimNFT is
    ERC721,
    AccessControl,
    IBurnable
{
    address private PBT_ADDRESS;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public supply;
    uint256 public constant MAX_SUPPLY = 350;
    uint256 public MIN_PRICE = 0.069 ether;

    /// @dev Event to emit on signature mint with the `tokenId`.
    event MintedUsingSignature(uint256 tokenId);
    event Minted(uint256 tokenId);

    mapping(address => uint256) pendingWithdrawals;

    /**
     * @dev Mapping to hold the state if token is minted. This is used to verify if a voucher
     * has been used or not.
     */
    mapping(uint256 => bool) private minted;

    constructor(address payable minter, address pbtAddress)
        ERC721("Blood of Moloch Claim", "BoMC")
    {
        require(pbtAddress != address(0), "BloodOfMolochClaimNFT: null address");
        _setupRole(MINTER_ROLE, minter);
        PBT_ADDRESS = pbtAddress;
    }

    function mintClaimToken() payable public {
        require(msg.value >= MIN_PRICE, "BloodOfMolochClaimNFT: msg.value below min price");
        _mintClaimToken();
    }

    function batchMintClaimTokens(uint256 _quantity) payable public {
        require(_quantity > 0, "BloodOfMolochClaimNFT: quantity cannot be zero");
        uint256 payment = MIN_PRICE * _quantity;
        require(msg.value >= payment, "BloodOfMolochClaimNFT: msg.value below min price");
        for(uint i=0; i<_quantity; i++) {
            _mintClaimToken();
        }
    }

    function mint() public onlyRole(MINTER_ROLE) {
        _mintClaimToken();
    }

    function batchMint(uint256 _quantity) external onlyRole(MINTER_ROLE) {
        require(_quantity > 0, "BloodOfMolochClaimNFT: quantity cannot be zero");
        for(uint i=0; i<_quantity; i++) {
            _mintClaimToken();
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Only authorized minters can withdraw"
        );

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = address(this).balance;
        receiver.transfer(amount);
    }

    function withdrawTokens(address _token) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Only authorized minters can withdraw"
        );

        address receiver = _msgSender();
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(receiver, balance);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (operator == PBT_ADDRESS) {
            return true;
        }
        return _operatorApprovals[owner][operator];
    }

    function setMinPrice(uint256 _minPrice) external onlyRole(MINTER_ROLE) {
        MIN_PRICE = _minPrice;
    }

    function _mintClaimToken() internal {
        uint tokenId = supply;
        require(tokenId + 1 <= MAX_SUPPLY, "BloodOfMolochClaimNFT: cannot exceed max supply");
        supply++;
        _mint(_msgSender(), tokenId);
        emit Minted(tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://bafybeia2wrcgdy7kux3q32anm4c4t2khagvaaz2vceg6ofptjgdj3xd6s4/";
    }

    receive() payable external {}
}