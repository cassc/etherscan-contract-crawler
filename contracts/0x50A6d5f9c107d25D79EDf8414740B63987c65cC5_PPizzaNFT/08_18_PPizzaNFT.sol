// SPDX-License-Identifier: MIT

//                                    &@@@@@@@@@
//                               ,@@@@,.....,,[email protected]@@
//                             420..,,,.,.....,,[email protected]@
//                        @@@@@ .........,,.,,//***@@
//                   &@@@@.....,,...,,,.,///////,,,[email protected]@@
//              ,@@@@...,,.....,,,,.//***..   .........,@@
//            @@&.......,,,,,,,(////**.    ...((((((([email protected]@.
//       @@@@@...,,,,...,,,,,//***    .....///((%##((///,,@@,
//     @@.,........,,,,,/////**          ((#####(((##(((((..&@@
//  @@@..,,,,,...,,/////((##%((...  .....############(((##[email protected]@
//  @@@.......,,,////(((##(((//(((..,,***..#############,,,,,[email protected]@
//     @@.,,,,,,,//**##########(((  ..,,,..   #######*****       @@@
//     @@.....,,,,,,,########//.....            .....****/,,,,,  @@@
//     @@//*.........,,,,,,,,...... ((((((((((.....  .....  ...((((#@@
//       @@@////*.........,....,,,((##########((   .......  (##((%##((@@@
//         [email protected]@@@&///////.......,,,,,,,########(((((         *//#######@@@
//              ,@@@@@@@/////.........,,,.,#######(       ..,,,#######((#@@
//                      @@@@&/////....,,,...,,,,,,,.......,,***//,,,##(((@@..
//                           ,,,,/&&&&&&&,,,,,,,........,,######(###//...,,**#%%
//                               .,,,,&@@,,...//,,,,,,,,..,,,,,#######***,,..&@@
//                                    &@@,,   &@,,,,,,,,,,,,...,,,,,,,...    ,,,&&.
//                                    &@@[email protected]@@  @@@,,...,,,,*,*,,...,,,,,[email protected]@,
//                                    &@@     69  [email protected]@,,,....&@@*//////.....,,,,,@@,
//                                    &@@..   @@  [email protected]@,,,[email protected]@.  @@@@@@@//////////@@,
//                                    &@@..   @@     @@@[email protected]@.         @@@@@@@@@@
//                                       @@@@@       @@@[email protected]@,
//                                                   @@@[email protected]@.
//                                                [email protected]@     @@,
//                                                [email protected]@...  @@.
//                                                [email protected]@...  @@,
//                                                   @@@@@

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PPizzaNFT is
    ERC721AQueryable,
    ERC721ABurnable,
    EIP712,
    Ownable,
    DefaultOperatorFilterer
{
    uint256 public maxSupply = 3369;
    uint256 public mintPrice = 0.003 ether;
    uint256 public maxMintPerAccount = 10;
    uint256 public totalNormalMint;
    uint256 public totalFreeMint;
    uint256 public publicSalesTimestamp = 1682780400;

    mapping(address => uint256) private _totalMintPerAccount;
    mapping(address => bool) public freeMinted; // 1 Free mint per account

    string private _contractUri;
    string private _baseUri;

    constructor()
        ERC721A("PPizza NFT", "PPIZZA")
        EIP712("PPizza NFT", "1.0.0")
    {}

    function mint(uint256 amount) external payable {
        require(isPublicSalesActive(), "Public sales is not active");
        require(totalSupply() < maxSupply, "Sold out!");
        require(totalSupply() + amount <= maxSupply,"Amount exceeds max supply");
        require(amount > 0, "Invalid amount");
        require(amount + _totalMintPerAccount[msg.sender] <= maxMintPerAccount,"Max tokens per account reached");

        if (freeMinted[_msgSender()]) {
            require(msg.value >= amount * mintPrice, "Invalid mint price");
        } else {
            require(msg.value >= mintPrice * amount - mintPrice,"Insufficient funds!");

            totalFreeMint += 1;
            freeMinted[_msgSender()] = true;
        }

        totalNormalMint += amount;
        _totalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(addresses.length == amounts.length,"Addresses and amounts doesn't match");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function totalMintPerAccount(address account) public view returns (uint256) {
        return _totalMintPerAccount[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setMaxMintPerAccount(uint256 maxMintPerAccount_) external onlyOwner {
        maxMintPerAccount = maxMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    //OpenseaOperatorFilterer
    function setApprovalForAll(address operator,bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}