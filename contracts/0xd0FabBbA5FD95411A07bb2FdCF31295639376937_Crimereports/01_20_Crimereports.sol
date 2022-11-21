pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./DefaultOperatorFilterer.sol";

interface IContraband {
    function balanceOf(address _address, uint256 _id)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract Wardenlist is Ownable {

    address private SIGNER;
    mapping(bytes => uint256) private usedSignaturesCounter;
    mapping(uint256 => uint256) public celblocks;


    // ------------------ Public ------------------ //

    function checkWardenList(address _toCheck, bytes memory _sig) public {
        require(_recoverSigner(_toCheck,_sig) == SIGNER, "Not on allowlist");
        require(usedSignaturesCounter[_sig]<2, "Signature used");
        usedSignaturesCounter[_sig]++;
    }

    // ------------------ Internal ------------------ //

    function _recoverSigner(address _toCheck, bytes memory  signature)
        internal
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_toCheck))
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function setSigner (address _signer) external onlyOwner{
        SIGNER= _signer;
    }

}

contract Crimereports is
    ERC721,
    Ownable,
    ReentrancyGuard,
    IERC1155Receiver,
    ERC2981,
    Wardenlist,
    DefaultOperatorFilterer
{
    constructor() ERC721("Cel Mates Crime Reports", "CRIMES") {
        currentPhase = MintPhase.CLOSED;
    }

    using Strings for uint256;

    enum MintPhase {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    IContraband CONTRABAND;

    MintPhase public currentPhase;

    uint256 MAX_SUPPLY = 4207;
    uint256 MINT_SUPPLY = 4098;
    uint256 mintPrice = 333000000000000000;
    string public BASE_URI;
    uint256 public mintIndex;
    address private vault;
    address private nsAddress;
    bool private uriMode;

    // ------------------ External ------------------ //

    function claim(
        uint256 _celblock,
        uint256 _amount,
        bytes memory _signature
    ) external payable nonReentrant {
        require(currentPhase != MintPhase.CLOSED, "Not opened");
        require(mintIndex + _amount <= MINT_SUPPLY, "Max reached");
        require(_celblock < 5, "0-4");
        require(_amount < 3, "1 or 2");
        require(msg.value == mintPrice * _amount, "Not exact ETH");

        for (uint256 i = 0; i < _amount; i++) {
            if (currentPhase != MintPhase.PUBLIC) {
                Wardenlist.checkWardenList(msg.sender, _signature);
            }

            uint256 celmate_id = mintIndex;
            _safeMint(msg.sender, celmate_id);
            celblocks[celmate_id] = _celblock;

            mintIndex++;
        }
    }

    function claimKey(uint256 _celblock) external nonReentrant {
        require(currentPhase != MintPhase.CLOSED, "Not opened");
        require(mintIndex < MAX_SUPPLY, "Max reached");
        require(_celblock < 6, "1-5");
        require(CONTRABAND.balanceOf(msg.sender, 0) > 0, "You don't own a key");
        CONTRABAND.safeTransferFrom(msg.sender, address(this), 0, 1, "");

        uint256 celmate_id = mintIndex;
        _safeMint(msg.sender, celmate_id);
        celblocks[celmate_id] = _celblock;

        mintIndex++;
    }

    // ------------------ Public ------------------ //

    function tokenURI(uint256 _celId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_celId));
        return
            string(
                uriMode ?
                abi.encodePacked(
                    BASE_URI,
                    celblocks[_celId].toString()
                ) :  abi.encodePacked(
                    BASE_URI,
                    _celId.toString()
                )
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function getOwnedCrimes(address _owner) public view returns(uint256[] memory){
        uint256[] memory result = new uint256[](balanceOf(_owner));
        uint256 counter = 0;
        for (uint256 i = 0; i < mintIndex; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;

    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ------------------ Owner ------------------ //

    function safeMint(address _to,uint256[] memory _celblocks, uint256 _amount) public onlyOwner {
        require(mintIndex + _amount <= MAX_SUPPLY, "Max reached");
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, mintIndex);
            celblocks[mintIndex]=_celblocks[i];
            mintIndex++;
        }
    }

    function setAddresses(
        address _vault,
        address _nsAddress,
        address _contraband
    ) external onlyOwner {
        vault = _vault;
        nsAddress = _nsAddress;
        CONTRABAND = IContraband(_contraband);
    }

    function withdraw() external onlyOwner {
        require(vault != address(0), "no vault");
        require(payable(nsAddress).send(address(this).balance / 20));
        require(payable(vault).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC2981,ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMintPhase(MintPhase _phase) external onlyOwner {
        currentPhase = _phase;
    }

    function setUriMode(bool _flag) external onlyOwner {
        uriMode = _flag;
    }

    function changeMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setBaseExtension(
        string memory _newBaseURI
    ) public onlyOwner {
        BASE_URI = _newBaseURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }
}