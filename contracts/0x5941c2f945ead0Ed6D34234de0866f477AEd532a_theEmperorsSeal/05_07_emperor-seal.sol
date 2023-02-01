/* SPDX-License-Identifier: MIT 
 
      ********************************
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      * ░░░██████████████████████░░░ *
      * ░░░██░░░░░░██░░░░░░████░░░░░ *
      * ░░░██░░░░░░██░░░░░░██░░░░░░░ *
      * ░░░██████████████████░░░░░░░ *
      * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
      ************************♥tt****/

pragma solidity ^0.8.17;

import "./utils/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract theEmperorsSeal is ERC721A, Ownable {
    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint256 royalties;
        string royaltiesRecipient;
    }

    ContractData public contractData =
        ContractData(
            unicode"The Emperor's Seal",
            unicode"The Emperor's Seal is a captivating story-driven collection of hand-drawn digital assets that explore the world of OUMM. Inspired by the story of OUMM and the concept of universal synchronicity, each piece of the collection is unique. The collection of 6666 comprises of 39 variations spread across 7 layers, each piece offering a unique glimpse into the rich history, regions, alliances, nations, tribes and diverse cultures of this imagined realm called OUMM. The vibrant and adventurous world of OUMM is the inspiration for this collection. OUMM is an ongoing epic adventure, artwork, design, stories and development are works of Kaus, founder of Kingdom Studios.",
            "https://ipfs.io/ipfs/bafybeid7itu7vcoowbx5hhe77skho5eydczffs6r43g2uy7tq6fdwsnxcu/pic1.jpg",
            "https://ipfs.io/ipfs/bafybeid7itu7vcoowbx5hhe77skho5eydczffs6r43g2uy7tq6fdwsnxcu/banner1.jpg",
            "https://kingdomstudios.space/",
            560,
            "0x5A8A362dE72d4A108155aeb86de22d7aFeaE4C6e"
        );

    uint256 fee = 0.035 ether;
    uint256 counter;
    bool public mintState = false;

    constructor() ERC721A("TheEmperorsSeal", "TES") {}


    receive() external payable {
        require(mintState, "Public minting is not active");
        publicMint(msg.value / fee);
    }

    function flipMintState() public onlyOwner {
        mintState = !mintState;
    }

    function publicMint(uint256 _quantity) public payable {
        require (mintState, "Mint is not active");
        require(msg.value >= (fee * _quantity), "Not enought eth");
        require(_quantity + counter <= 6666);

        counter += _quantity;
        _mint(msg.sender, _quantity);
    }

    //metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            contractData.name,
                            '","description":"',
                            contractData.description,
                            '","image":"',
                            contractData.image,
                            '","banner":"',
                            contractData.banner,
                            '","external_link":"',
                            contractData.website,
                            '","seller_fee_basis_points":',
                            _toString(contractData.royalties),
                            ',"fee_recipient":"',
                            contractData.royaltiesRecipient,
                            '"}'
                        )
                    )
                )
            );
    }

    function setContractData(ContractData memory _contractData)
        external
        onlyOwner
    {
        contractData = _contractData;
    }

    //withdraw addresses
    address public vault = 0x5A8A362dE72d4A108155aeb86de22d7aFeaE4C6e;
    address public dev = 0xa4bAa7B5dC8a4eF2c8E346F21ae641aEe73a722A;
    address public heartKidsNZ = 0x79dE77625FdB5CC37Fd9cA3570b06E60eAf1EA46; //charity address

    //withdraw eth
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        uint256 five = (balance * 5) / 100; 
        uint256 eight = (balance * 8) / 100; 
        Address.sendValue(payable(heartKidsNZ), five);
        Address.sendValue(payable(dev), eight);
        Address.sendValue(payable(vault), balance - (eight+five));
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }
}