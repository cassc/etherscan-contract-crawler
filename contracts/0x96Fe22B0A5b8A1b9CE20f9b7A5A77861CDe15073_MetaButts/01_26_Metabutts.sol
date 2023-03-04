// SPDX-License-Identifier: UNLICENSED

/*                        
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
....................................,,::;;++++++++;;::,...................................
..............................,,;+*?%%%SSSSSSS#####@@##S%*+:,.............................
...........................,;+??%%%%%%%%%%%%%%%%SSSS###@@@@@#%+:..........................
........................:;*?????????????????????%%%%SSS###@@@@@@S*:.......................
.....................,:+*******???*************????%%%SSS####@@@@@@S+,....................
...................,;++++*************************???%%%SSS####@@@@@@#*,..................
.................,;+++++++***********++++++++++****????%%SSS####@@@@@@@#*,................
................:;+;;++++*********+++++++++++++*****????%%%SSS####@@@@@@@S;...............
..............,;;;;;+++++********+++++++++++++++*****????%%%SSS####@@@@@@@@*..............
.............,;;;;;;+++++*********+++;;;;++++++++*****????%%%SSS####@@@@@@@@%,............
............:;;;;;;;;+++++******??*+;;;;;+++++++++*****???%%%%SSS####@@@@@@@@S,...........
...........:;::;;;;;;++++++*****????*;;+++;;++++++++****???%%%%SSS####@@@@@@@@S,..........
..........:::::;;;;;;+++++++****??%SS?++;;;;;;+++++++****???%%%SSSS####@@@@@@@@S,.........
.........,:::::;;;;;;+++++++****??%S#S+;;;;;;;;++++++****????%%%SSSS###@@@@@@@@@?.........
........,::::::;;;;;;;++++++****??%[email protected]+;;;;;;;;;++++++****????%%%SSS####@@@@@@@@@;........
........:::::::;;;;;;;;++++++***??%[email protected]%+;;;;;;;;;;++++++****???%%%SSSS###@@@@@@@@@S........
.......,:::::::;;;;;;;;+++++****?%%[email protected]%+;;;;;;;;;;;+++++****????%%%SSS####@@@@@@@@@;.......
.......,::::::;;;;;;;;;+++++****?%%[email protected]%+;;;;;;;;;;;++++++****???%%%SSSS###@@@@@@@@@?.......
.......:::::::;;;;;;;;++++++***??%%[email protected]%+;;;;;;;;;;;++++++****???%%%%SSS###@@@@@@@@@#.......
.......::::::;;;;;;;;++++++****??%[email protected]++;;;;;;;;;;++++++****????%%%SSS####@@@@@@@@#,......
.......:;::;;;;;;;;;;+++++*****??%[email protected]*++;;;;;;;;;++++++****????%%%SSS####@@@@@@@@#,......
.......:;;;;;;;;;;;++++++*****???%SS#@?+++++;;;;++++++++****????%%%SSS####@@@@@@@@S.......
.......,;;;;;;;+++++++++*****???%%SS#@S*+++++++++++++++*****????%%%SSS###@@@@@@@@@?.......
........:+;;;+++++++++*****????%%%SS#@@?**++++++++++++*****????%%%SSSS###@@@@@@@@@:.......
........,;+++++++++******?????%%%SS##@@#?*****+++*********????%%%%SSS####@@@@@@@@*........
.........,+************?????%%%%SSS##@@@#??*************?????%%%%SSS####@@@@@@@@?.........
..........,+***??????????%%%%%SSSS###@@@@@%????????????????%%%%%SSS####@@@@@@@@*..........
............:*?%?????%%%%%%SSSSS####@@@@@@@#S%%%???????%%%%%%SSSSS####@@@@@@@S;...........
..............:*%SSSSSSSSSSSS#####@@@@@@@@#?;*%SSS%%%%%%%SSSSSS#####@@@@@@@S+,............
................,;*%S#######@@@@@@@@@@#%*:....,:*%S####SSS#######@@@@@@@S*:...............
....................,:+*?%%SSSSS%?*+;,,...........,;+?%S###@@@@@@@#S%?+:..................
........................................................,::::;;::,,.......................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................
..........................................................................................                                                           
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {DefaultOperatorFilterer, OperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MetaButts is
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 public maxSupply = 4000;
    uint256 public mintPrice = 0.025 ether;
    uint256 public maxPerAddressWaitlistPublic = 2;
    string public baseURI =
        "https://ipfs.io/ipfs/QmbKMKufRqeo1C2zxk8jooriJNmrXMx1V8E8EjeoGGNhpu/QmUUGKrzyRdA71Hy3xLN4qfhass7fJXqyyQWRKcq9kXLhw";
    string public baseExtension = ".json";

    bytes32 public waitlistRoot = 0x7ebf141fe500f9e29071d3113b3074504d1377c363e61c7670ea7098cbc539f8;

    enum Status {
        NOTSTARTED,
        WAITLIST,
        PUBLIC,
        REVEAL
    }

    Status public state;

    constructor() ERC721A("MetaButts", "METABUTTS") {}

    function getNumberMinted(address _address) external view returns (uint256) {
        return _numberMinted(_address);
    }

    function setState(Status _state) external onlyOwner {
        state = _state;
    }

    function isWaitlist(address sender, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                waitlistRoot,
                keccak256(abi.encodePacked(sender))
            );
    }

    function mintWaitlist(bytes32[] calldata proof, uint256 amount)
        public
        payable
    {
        require(state == Status.WAITLIST, "MetaButts: Waitlist mint not started");
        require(isWaitlist(msg.sender, proof), "MetaButts: Cannot mint waitlist");
        require(
            amount + totalSupply() <= maxSupply,
            "MetaButts: Max supply exceeded"
        );
        require(
            mintPrice * amount <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            _numberMinted(msg.sender) + amount <= maxPerAddressWaitlistPublic,
            "MetaButts: Exceeded total amount per address"
        );
        _safeMint(msg.sender, amount);
    }

    function mintPublic(uint256 amount) public payable {
        require(state == Status.PUBLIC, "MetaButts: Public mint not started");
        require(
            amount + totalSupply() <= maxSupply,
            "MetaButts: Max supply exceeded"
        );
        require(
            mintPrice * amount <= msg.value,
            "Ether value sent is not correct"
        );
        require(
            amount <= 2,
            "MetaButts: Exceeded total amount per transaction"
        );
        _safeMint(msg.sender, amount);
    }

    function mintDev(address _address, uint256 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity <= maxSupply,
            "MetaButts: Exceeds total supply"
        );
        _safeMint(_address, _quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        if (state != Status.REVEAL) {
          return currentBaseURI;
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, IERC721A)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setWaitlistRoot(bytes32 _newRoot) public onlyOwner {
        waitlistRoot = _newRoot;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
      maxSupply = newSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
      mintPrice = newPrice;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /* ------------ OpenSea Overrides --------------*/
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}