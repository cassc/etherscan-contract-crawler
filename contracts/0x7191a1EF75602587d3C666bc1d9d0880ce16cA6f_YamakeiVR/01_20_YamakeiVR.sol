// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title: NFTBoil
/// @author: HayattiQ
/// @dev: This contract using NFTBoil (https://github.com/HayattiQ/NFTBoil)

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import './extensions/ERC721ALockable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract YamakeiVR is ERC721ALockable, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    string private baseURI = '';

    bool public presale = false;
    uint256 public presale_max = 1;
    bool public mintable = true;
    address public royaltyAddress;
    uint96 public royaltyFee = 500;

    uint256 public constant MAX_SUPPLY = 300;
    string private constant BASE_EXTENSION = '.json';
    uint256 private constant PUBLIC_MAX_PER_TX = 1;
    address private constant DEFAULT_ROYALITY_ADDRESS =
        0xFbD1977ebf1Af6a492754B096304fC44459371B8;
    bytes32 public merkleRoot;
    mapping(address => uint256) private whiteListClaimed;

    constructor() ERC721A('YamakeiVR', 'YAMA') {
        _setDefaultRoyalty(DEFAULT_ROYALITY_ADDRESS, royaltyFee);
    }

    modifier whenMintable() {
        require(mintable == true, 'Mintable: paused');
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function publicMint(uint256 _mintAmount)
        public
        whenNotPaused
        whenMintable
        callerIsUser
    {
        mintCheck(_mintAmount, 0);
        require(!presale, 'Presale is active.');
        require(_mintAmount <= PUBLIC_MAX_PER_TX, 'Mint amount over');

        _mint(msg.sender, _mintAmount);
    }

    function preMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        whenMintable
        whenNotPaused
    {
        mintCheck(_mintAmount, 0);
        require(presale, 'Presale is not active.');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf),
            'Invalid Merkle Proof'
        );

        require(
            whiteListClaimed[msg.sender] + _mintAmount <= presale_max,
            'Already claimed max'
        );
        _mint(msg.sender, _mintAmount);
        whiteListClaimed[msg.sender] += _mintAmount;
    }

    function mintCheck(uint256 _mintAmount, uint256 cost) private view {
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, 'MAXSUPPLY over');
        require(msg.value >= cost, 'Not enough funds');
    }

    function ownerMint(address _address, uint256 count) public onlyOwner {
        _mint(_address, count);
    }

    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    function setMintable(bool _state) public onlyOwner {
        mintable = _state;
    }

    function setPreMax(uint256 _max) public onlyOwner {
        presale_max = _max;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /**
     * @dev Admin専用。 解除の時は null addressでadminLock
     */
    function adminLock(address unlocker, uint256[] calldata ids)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            unlockers[ids[i]] = unlocker;
        }
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ALockable, ERC2981)
        returns (bool)
    {
        return
            ERC721ALockable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}