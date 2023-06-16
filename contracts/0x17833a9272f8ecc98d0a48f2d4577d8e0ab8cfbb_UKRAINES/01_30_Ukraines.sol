// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./lib/Base.sol";

interface IMolfar {
    function burn(address account, uint256 id, uint256 value) external;
}

contract UKRAINES is Base {

    uint public signedPrice = 0.0198 ether;
    uint public publicPrice = 69.420 ether;

    address public MOLFARS = 0xEa823a96EaE4126353dC78a851a16B90EE793568;

    uint public mintRound = 0;

    constructor(
        string memory name_,
        string memory symbol_,
        address signer_,
        string memory uri_
    ) Base(name_, symbol_, signer_, uri_) {
        _setDefaultRoyalty(msg.sender, 500);
    }

    // Mint (Public)
    function mintPublic(
        uint howMany
    ) external payable checkSupply(howMany){
        if(msg.value < publicPrice * howMany) {
            revert InsufficientFunds();
        }
        _mint(_msgSender(), howMany);
    }

    function setPublicPrice(
        uint publicPrice_
    ) external payable onlyOwner {
        publicPrice = publicPrice_;
    }

    function setSignedPrice(
        uint signedPrice_
    ) external payable onlyOwner {
        signedPrice = signedPrice_;
    }

    // Mint (With signature)
    function mintSigned(
        bytes calldata signature,
        uint howMany,
        uint allowed,
        uint nonce
    ) external payable  checkSupply(howMany) {
        if (nonce < mintRound) {
            revert InvalidSignature();
        }
        if(msg.value < signedPrice * howMany) {
            revert InsufficientFunds();
        }
        if(_numberMinted(_msgSender()) + howMany > allowed) {
            revert ExceedsMaxSupply();
        }
        if(!verify(signature, _msgSender(), allowed, nonce)) {
            revert InvalidSignature();
        }
        _mint(_msgSender(), howMany);
        
    }

    function mintWithMolfar(
        uint howMany
    ) external payable {
        if(mintRound!=666){
            revert NotMintable();
        }
        IMolfar(MOLFARS).burn(_msgSender(), 666, howMany);
        _mint(_msgSender(), howMany);
    }

    function setMintRound(uint mintRound_) external payable onlyOwner {
        mintRound = mintRound_;
    }

    // Airdrop
    function airdrop(
        address to_,
        uint howMany
    ) external payable onlyOwner checkSupply(howMany) {
        _mint(to_, howMany);
    }

    function airdropToMany(
        address[] calldata to_,
        uint howMany
    ) external payable onlyOwner checkSupply(howMany * to_.length) {
        uint to_length = to_.length;
        for (uint i = 0; i < to_length; ) {
            _mint(to_[i], howMany);
            unchecked {
                ++i;
            }
        }
    }

}