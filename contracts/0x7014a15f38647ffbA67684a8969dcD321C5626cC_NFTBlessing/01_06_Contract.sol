//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFTBlessing is Ownable {

    enum Blesser{None, Legendary, Angel, Anonymous, Cagehead, Demon, MrRoot, TimeTraveler, Undead, Zombie}
    enum State{OFF, WHITELIST, ALL}
    struct Blessing{
        Blesser blesser;
        uint256 assetId;
    }

    IERC721 darkflex = IERC721(0x765dA497beAF1C7D83476C0e77B6CABA672dEfb9);
    address burnWallet = 0x000000000000000000000000000000000000dEaD;

    Blesser public currentBlesser = Blesser.None;
    uint256 public blessingCeil = 0;
    uint256 public numCurrentBlessings = 0;

    uint256 public metadataHash;

    State public currentState = State.OFF;

    mapping(uint256 => Blessing) public blessedNFTs;
    mapping(address => Blesser) public walletPrevBlessed;

    bytes32 public whitelistRoot;

    constructor(){
        blessedNFTs[578] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[1236] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[1987] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[2430] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[3014] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[4241] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[5506] = Blessing(Blesser.Legendary, 0xffff);
        blessedNFTs[6148] = Blessing(Blesser.Legendary, 0xffff);
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) public onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setState(State state) public onlyOwner {
        currentState = state;
    }

    function configBlessing(Blesser blesser, uint256 _blessingCeil, uint256 _metadataHash) public onlyOwner {
        currentBlesser = blesser;
        blessingCeil = _blessingCeil;
        metadataHash = _metadataHash;
        numCurrentBlessings = 0;
    }

    function getNftStatus(uint256 tokenid) public view returns(Blessing memory) {
        Blessing memory token = blessedNFTs[tokenid];
        if((token.blesser == Blesser.None) || (token.blesser == Blesser.Legendary)){
            return Blessing(Blesser.None, 0);
        } else if((token.blesser == currentBlesser) && (currentState != State.OFF)) {
            return Blessing(token.blesser, 2**255);
        }
        return token;
    }

    function walletCanBless() public view returns(bool){
        return walletPrevBlessed[msg.sender] != currentBlesser;
    }

    /*
    * Blesses one nft by burning the other.
    * @return hash of your new token's image
    */
    function bless(uint256 blessed, uint256 burned, bytes32[] calldata _merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require((currentState == State.ALL) || (currentState == State.WHITELIST && MerkleProof.verify(_merkleProof, whitelistRoot, leaf)), "Either state is off or you're not in whitelist.");
        require(walletPrevBlessed[msg.sender] != currentBlesser, "You can only bless once per event.");
        require(blessedNFTs[blessed].blesser == Blesser.None, "Blessed NFT has been blessed before");
        require(blessedNFTs[burned].blesser == Blesser.None, "Burned NFT has been blessed before");
        require(blessingCeil > numCurrentBlessings, "All blesings already done.");

        require(darkflex.ownerOf(blessed) == msg.sender, "You have to own the token you are blessing.");
        darkflex.safeTransferFrom(msg.sender, burnWallet, burned);

        blessedNFTs[blessed] = Blessing(currentBlesser, numCurrentBlessings);
        walletPrevBlessed[msg.sender] = currentBlesser;
        numCurrentBlessings += 1;
    }
}