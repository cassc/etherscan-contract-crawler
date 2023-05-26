// SPDX-License-Identifier: MIT

//                   .            .
//      ___    ___  _/_     ___   |     __.    ___.
//    .'   `  /   `  |     /   `  |   .'   \ .'   `
//    |      |    |  |    |    |  |   |    | |    |
//     `._.' `.__/|  \__/ `.__/| /\__  `._.'  `---|
//                                           \___/

// screenshots.sol by @worm_emoji
// luke.cat :-)

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

pragma solidity >=0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract screenshots is Ownable, ERC721 {
    string public baseURI = "https://mint.luke.cat/api/metadata/";
    address public signer;
    uint256 public mintPrice = 80000000000000000; // 0.08 eth
    bool public publicMintActive = false;

    uint256 private _royaltyPct = 10;

    constructor(address _signer)
        ERC721("screenshot catalog by worm_emoji", "CAT")
    {
        signer = _signer;
    }

    function mint(uint256 tokenID, bytes memory signature) public payable {
        // There used to be a check here to see if the NFT was minted, but
        // solmate's _mint function does it internally. If you're modifying
        // this contract and you're adding more side effects to this contract
        // besides just minting, you may want to re-add a check to see if it's
        // minted.

        require(publicMintActive, "Public minting is not active");
        require(msg.value == mintPrice, "Wrong price");

        // Check that the minter is allowed to mint.
        // The purpose of this check is to control what token IDs can be
        // minted without having to update the contract – just sign the tokenID
        // with a known key.
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
            keccak256(abi.encodePacked(tokenID)),
            signature
        );
        require(
            error == ECDSA.RecoverError.NoError && recovered == signer,
            "Invalid signature"
        );

        _mint(msg.sender, tokenID);
    }

    function creatorMint(uint256 tokenID) public onlyOwner {
        require(ownerOf[tokenID] == address(0), "Token already minted");
        _mint(this.owner(), tokenID);
    }

    function updateSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function updateMintPrice(uint256 _price) public onlyOwner {
        mintPrice = _price;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPublicMint(bool _isPublicMintActive) public onlyOwner {
        publicMintActive = _isPublicMintActive;
    }

    function setRoyaltyPct(uint256 newRoyaltyPct) public onlyOwner {
        _royaltyPct = newRoyaltyPct;
    }

    function tokenURI(uint256 tokenID)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }

    function withdraw() external {
        payable(this.owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(this.owner(), _amount);
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (_royaltyPct < 1) {
            return (address(0), 0);
        }
        receiver = address(this);
        royaltyAmount = _salePrice / _royaltyPct;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; // ERC165 Interface ID for https://eips.ethereum.org/EIPS/eip-2981
    }
}