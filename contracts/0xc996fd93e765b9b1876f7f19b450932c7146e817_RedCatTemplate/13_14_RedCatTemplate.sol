/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@&#P!^!PGP55Y55PGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G!~?P@@@@@@@@@@GJ~:. .:!JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@B.                .^?P@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~   .#@@@@@@@P^   ~JYJ~   ^5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@&P^   !GGB#####BPY~   ^B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:   !@@@@@@&7   ~B@@@@@B7. .G@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5!!7Y#@@@@@@@@@@@
@@@@@@@@@~   5@@@@@@@@@@@@~   ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:   J@@@@@&~   7@@@@@@@@@&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@^    ?@@@@@@@@@@@
@@@@@@@@@~   P@@@@@@@@@@@G:   ?@@@@@@@@@@#GPGGB#&@@@@@@@@@@@@@BPYYY5G&#.   5@@@@@?   ~@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGB#@@@@@@@@@@@@@^    G@@@@@@@@@@@
@@@@@@@@@~   G@@@@@@@&B5!   .?&@@@@@@@#J^       :~JB@@@@@@@@5^       .~    G@@@@G    G@@@@@@@@@@@@@@@@@@@@@@&GJ!:.     .^?B@@@@@B555Y.    ?JJYP@@@@@@@
@@@@@@@@@!   5BGPYJ7~:   .~Y#@@@@@@@@5.   !5GG5J~   ~B@@@@#~   .?PGPY^     G@@@@7   ~@@@@@@@@@@@@@@@@@@@@@@J.   .!J55Y7.   J@@@@?          .:^J&@@@@@@
@@@@@@@B!.          :~7YG#@@@@@@@@@@?   .P@@@@@@@Y   !@@@&^   ^#@@@@@@7    G@@@&^   ?@@@@@@@@@@@@@@@@@@@@@@J::~5&@@@@@@B:   J@@@&P55Y.   ~#&@@@@@@@@@@
@@@@@@@B!.   ~J7:   ^Y&@@@@@@@@@@@@P    ^G&&&&#BY^  :P@@@J   .#@@@@@@@G    B@@@#.   Y@@@@@@@@@@@@@@BG#@@@@@@@&#BPY?!~^^:.   ^@@@@@@@#.   7@@@@@@@@@@@@
@@@@@@@@@?   J@@&G?:  .7P@@@@@@@@@@!    . ..:..  :75&@@@@^   !@@@@@@@@Y   .B@@@@^   ?@@@@@@@@@@@@P~   G@@@@BJ~.  .:~!7??^   :&@@@@@@B    ?@@@@@@@@@@@@
@@@@@@@@@J   ?@@@@@&P!.  ^J#@@@@@@@?    Y#P555PG#@@@@@@@@~   ~@@@@@@@#:   .#@@@@P   .5@@@@@@@@BY^   ^P@@@@Y    7B&@@@@@@!   :&@@@@@@B    ?@@@@@@@@@@@@
@@@@@@@@@J   !@@@@@@@@#Y^  .!5#&@@@#^   .5&@@@@@&GY!~5@@@G.   J#@@@#Y.    .#@@@@@G^   ^JY5YJ!:    ~5@@@@@@7    ?B&&&#BY~    :&@@@@@@&^   !@@&BG&@@@@@@
@@@@@@@@@G.   P@@@@@@@@@@G!.   .P@@@&J^.  .^~~^:.  .~P@@@@#?:   :::  :7    G@@@@@@@G?^.      .^75B@@@@@@@@&Y~.   ...   ^:   .&@@@@@@@B^   ~?: .G@@@@@@
@@@@@@@@@@#P5P&@@@@@@@@@@@@#57!Y&@@@@@@#PY?777??YPB&@@@@@@@@&BPY???YG&@Y~^!B@@@@@@@@@@&BBGGB#&@@@@@@@@@@@@@@@&BP55Y5PB#@G~:^J@@@@@@@@@@GY?7?YG&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Ownable.sol';
import './ERC721A.sol';
import './MerkleProof.sol';

contract RedCatTemplate is ERC721A, Ownable {

    using Strings for uint256;
    uint public maxMint;
    uint public porfit;
    uint public maxTotal;
    uint public price;
    uint public mintTime;
    bool public preMintOpen;
    bool public publicMintOpen;
    bool public blindBoxOpen;
    bool public useBlind;
    address public withdrawAddress;
    string public baseTokenURI;
    string public blindTokenURI;
    bytes32 public merkleRoot;
    
    constructor(string memory name, string memory symbol, uint _maxMint, uint _porfit, uint _maxTotal, uint _price, uint _mintTime, string memory _baseTokenURI) ERC721A(name, symbol)  {
        maxMint = _maxMint;
        porfit = _porfit;
        maxTotal = _maxTotal;
        price = _price;
        mintTime = _mintTime;
        baseTokenURI = _baseTokenURI;
        withdrawAddress = tx.origin;
    }

    function preMint(uint256 num, bytes32[] calldata proof_) public payable {
        uint256 supply = totalSupply();
        require(verify(proof_), "address is not on the whitelist");
        require(preMintOpen, "no mint time");
        require(num <= maxMint, "You can adopt a maximum of MAX_MINT Cats");
        require(supply + num <= maxTotal, "Exceeds maximum Cats supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(block.timestamp >= mintTime, "no mint time");

        _safeMint(msg.sender, num);
    }

    function publicMint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(publicMintOpen, "no mint time");
        require(num <= maxMint, "You can adopt a maximum of MAX_MINT Cats");
        require(supply + num <= maxTotal, "Exceeds maximum Cats supply");
        require(msg.value >= price * num, "Ether sent is not correct");
        require(block.timestamp >= mintTime, "no mint time");

        _safeMint(msg.sender, num);
    }

    function getAirDrop(uint16 _num, address recipient) public onlyOwner {
        _safeMint(recipient, _num);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setPreMintOpen() public onlyOwner {
        preMintOpen = !preMintOpen;
    }

    function setPublicMintOpen() public onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setBlindBoxOpened() public onlyOwner {
        blindBoxOpen = !blindBoxOpen;
    }

    function setUseBlind() public onlyOwner {
        useBlind = !useBlind;
    }

    function setMintTime(uint256 _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setMintPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setPorfit(uint256 _porfit) public onlySteven {
        porfit = _porfit;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBlindTokenURI(string memory _blindTokenURI) public onlyOwner {
        blindTokenURI = _blindTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawAll() public onlyOwner {
        uint one = address(this).balance * (100 - porfit) / 100;
        uint two = address(this).balance * porfit / 100;
        require(payable(withdrawAddress).send(one));
        require(payable(redCat()).send(two));
    }

    function verify(bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if(useBlind) {
            if (blindBoxOpen) {
                string memory baseURI = _baseURI();
                return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
            } else {
                return blindTokenURI;
            }
        } else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';    
        }
    }
}