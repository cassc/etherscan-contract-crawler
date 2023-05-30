// SPDX-License-Identifier: MIT
/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmdmMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMy+:--/NMMh-```:NMMy/:+hMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNMMMMs```.:yMMm``./``+Mh`````/MMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMy:.../yMs````./mMs``.+``.M-``o.``mMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMM.```-``/N.```-..:o``.:``:h```/``-MMMMMMNh++yNMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMh.``s.``dd.```.:ym/:yd::hy.```./mMMMMmo..:``hMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMh.````-NMmyydmNMMMMMMMNMMmdhdmMMMMMM:-/`..smMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMd+omMMMMd/--+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNs:+o/-sNMMMMMMMMMMMMM
MMMMMMMMNmMMmNo..+dMMMMMmNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo/yo:ddmMMMMMMMMMMM
MMMMMMMMh-os-:o+/sNMMMMMMMMMMMMMMNNmmmmmmmNMMMMMMMMMMMMMMMMMMMMMd/:.-hMMMMMMMMMM
MMMMMMhoNh-`-s:sMMMMMMMMMMMMmmho/:-..```..-/oymNMMMMMMMMMMMMMMMMmy/.``sMMMMMMMMM
MMMMMh`.mMNs-:NMMMMMMMMMNho:.```````````..`````:ohNMMMMMMMMMMMMMMNy:--/mNMMMMMMM
MMMMd.---+dNNNMMMMMMMMm+.````````````````:/```````-sNMMMMMMMMMMMMMMho/::yMMMMMMM
MMMMmhNMh+-sMMMMMMMMMy.```````````````````.-``````.-+NMMMMMMMMMMMMdy+`-+/yMMMMMM
MMMMMMMMMMMMMMMMMMMMs.```````````````````````````.-/oyMMMMMMMMMMMMdoosyhmMMMMMMM
MMMMMMMMMMMMMMMMMMMm....`````````````````````````./ohdmMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMdNMMMMMMMMy-:-/``````````````````````````````:omMMMMMMMMMMMMMdMMMMMMMMM
MMMMMMMMM-yMMMMMMMMh//:+:```:--```....```````````````````dMMMMMMMMMMMm`NMMMMMMMM
MMMMMMMMN/+MMMMMMMMNs++o-``/``/ymMMMMMMNy-````-ohddddho-`.NMMMMMMMMMMs:mMMMMMMMM
MMMMMMMMM.:MMMMMMMMMmyhh````.dMMMMMMMMo:my```sMMMMMMs+Ns``yMMMMMMMMMMo`mMMMMMMMM
MMMMMMMMM+-MNMMMMMMMMMmy````oMMMMMMMMMmyNM.``NMMMMMMdomN``sMMMMMMMMMM/:NMMMMMMMM
MMMMMMMsyy`ho/NMMMMMMMM+````sMMMMMMMMMMMMm```hMMMMMMNNMM``oMMMMMMNs+d.ohsNMMMMMM
MMMMMMM+:d`o+.m.mMMMMMMo````-NMMMMMMMMMMd--dy:mMMMMMMMMy``sMMMMM:h::h`y+-MMMMMMM
MMMMMMMy-s:/o:o-dMMMMMMh```.::ydNNmmddy/`.mMMm-shhdddy+`.`mMMMMN-o/++-y:+MMMMMMM
MMMMo+oh``-:.-``hMMMMMMM+``:--........``.oh/+h-```````-:.oMMMMMm.`.`:.``ysooMMMM
MMMMh-:ms`/-.+`oMMMMMMMMNh+::-.``.```````.```````````.:-sMMMMMMMs`/.//`/N+.sMMMM
MMMMMNoys.`...`mMMMMMMMMMMMMNNmmhh/````````````````-oydNMMMMMMMMM....``sy/dMMMMM
MMMMMMMMmy+yhysNMMMMMMMMMMMMMMMMMMy```:.```.:```/`-NMMMMMMMMMMMMMssys++mNMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:--s-..-o-`.//-yMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMmmMNmmNMmdmNmmMMMMMMMMMMMNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNNs//mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMd//+NMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMs::o/dmyMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmdomo:`/hMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMmsoNm+./mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMmdMN:/s:mm+omMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMN+:-ymdyNMmoNMMMMMMMMMMMMMMMMMMdyoMy.hMm+/:oMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNmMo-/dd-yMNmMMmoMMMMMMMMMMMMy`:NMy.ssMmmMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMdNN:dM+--Mm-:MNsyMd/+oMMMM/`/hMhhNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMdsNMN.yMs-:My-y:MMMMNhMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 */
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title The Dead Army Skeleton Klub
/// @author Burn0ut#8868 [email protected]
/// @notice https://www.thedeadarmyskeletonklub.army/ https://twitter.com/The_DASK
contract DASKa is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 6969;
    uint256 public constant MAX_PER_MINT = 20;
    address public constant w1 = 0x9AEc8C528263746A6058CafaF7099bf5DCa452e3;
    address public constant w2 = 0x8deddE67889F0Bb474E094165A4BA37872A7c26B;

    uint256 public price = 0.069 ether;
    bool public isRevealed = false;
    bool public publicSaleStarted = false;
    bool public presaleStarted = false;
    mapping(address => uint256) private _presaleMints;
    uint256 public presaleMaxPerWallet = 6;

    string public baseURI = "";
    bytes32 public merkleRoot = 0x7d47dd9d8fd212164c3a9e8d23f89077455d468a3e287590d7f66b9c5ed8dcfd;

    constructor() ERC721A("Dead Army Skeleton Klub", "DASK", 20) {
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        } else {
            return
                string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/QmQPrJkT8cX72rasGdoMnWq713DwTGniMxxPadjVzgxmbG/", tokenId.toString()));
        }
    }

    /// Set number of maximum presale mints a wallet can have
    /// @param _newPresaleMaxPerWallet value to set
    function setPresaleMaxPerWallet(uint256 _newPresaleMaxPerWallet) external onlyOwner {
        presaleMaxPerWallet = _newPresaleMaxPerWallet;
    }

    /// Presale mint function
    /// @param tokens number of tokens to mint
    /// @param merkleProof Merkle Tree proof
    /// @dev reverts if any of the presale preconditions aren't satisfied
    function mintPresale(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(presaleStarted, "DASK: Presale has not started");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "DASK: You are not eligible for the presale");
        require(_presaleMints[_msgSender()] + tokens <= presaleMaxPerWallet, "DASK: Presale limit for this wallet reached");
        require(tokens <= MAX_PER_MINT, "DASK: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "DASK: Minting would exceed max supply");
        require(tokens > 0, "DASK: Must mint at least one token");
        require(price * tokens == msg.value, "DASK: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
        _presaleMints[_msgSender()] += tokens;
    }

    /// Public Sale mint function
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the public sale preconditions aren't satisfied
    function mint(uint256 tokens) external payable {
        require(publicSaleStarted, "DASK: Public sale has not started");
        require(tokens <= MAX_PER_MINT, "DASK: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "DASK: Minting would exceed max supply");
        require(tokens > 0, "DASK: Must mint at least one token");
        require(price * tokens == msg.value, "DASK: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    /// Owner only mint function
    /// Does not require eth
    /// @param to address of the recepient
    /// @param tokens number of tokens to mint
    /// @dev reverts if any of the preconditions aren't satisfied
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "DASK: Minting would exceed max supply");
        require(tokens > 0, "DASK: Must mint at least one token");

        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "DASK: Insufficent balance");
        _widthdraw(w2, ((balance * 5) / 100));
        _widthdraw(w1, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "DASK: Failed to widthdraw Ether");
    }

}