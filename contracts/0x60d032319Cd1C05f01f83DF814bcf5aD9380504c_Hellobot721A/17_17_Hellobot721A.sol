pragma solidity ^0.8.13;
import "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@ERC721A/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@OperatorFilterer/src/DefaultOperatorFilterer.sol";

/*                                                                                          
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMFIMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM:..:VNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.....VNNNNNNNNNNNNNNNNNNNNNN$F*VNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM..::..:MNNNNNNNNNNNNNNNNNNN$*....MNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNF........:...::::***FV$MNNNV...:..$NNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.......................:**...::..$NNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN:.................................NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM.................................*NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN$........FF***....................INNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNF........:$NNN*......:IF**:.......MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.........*IV*........*NNNM......*NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM................**::...*II:......INNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNV................FNMI.............$NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*............V*..:N*.............:NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN:............*VVV$NIF*...........*NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNV..................::::...........VNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.................................MNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN:................................:NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNV.................................:NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.................................*NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNM..................................FNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNI.............................*F$MM$$$$MNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN:..........................:IM$I*********I$MNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN$..........................*M$***************$NNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.........................*NV*****************MNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNM..........................M$............::****$NNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNN*.........................*N*................::MNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNF..........................IN:.................INNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNM*...........................VN................:MNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNN$:............................IN.................VNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNF..............................FN:................:MNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNN$:...............................*N*.................FNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNN$:.................................MV..................$NNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNN$...................................VM..................*NNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNM:...................................*N*..................VNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNI................:VF*::...............:...................:MNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNN*.................:*FV$$$VF**::............................INNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNN*........................:**FIV$$VIF*:.....................*NNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNN*................................::*FVM$*:..................NNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNV.....................................*FVMV:................MNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNN*....................................****VM*...............MNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNM:...................................*****VN*.............:NNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNF:................................:******$M.............VNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNMI:..............................*******$M...........:VNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNMV*:.........................:******FMV........:*IMNNNNNNNNNNNNNNNNNNNNNNN           
*/
contract Hellobot721A is
    ERC721AQueryable,
    ERC721ABurnable,
    DefaultOperatorFilterer,
    Ownable,
    ERC2981
{
    uint256 constant TOTAL_SUPPLY = 5300;
    uint256 constant PUBLIC_SUPPLY = 4747;
    uint256 constant TEAM_SUPPLY = 553;
    uint256 public teamMinted = 0;

    string tokenBaseUri = "";

    constructor() ERC721A("Hellobot Universe Official", "HellobotNFT") {
        _mint(msg.sender, 1);
        _setDefaultRoyalty(msg.sender, 750);
    }

    function airdrop(address[] calldata airdropList, uint256[] calldata quantity) external onlyOwner {
        require(airdropList.length == quantity.length, "wrong length");
        for(uint i = 0 ; i < airdropList.length ; i++) {
            safeMint(airdropList[i], quantity[i]);
        }
    }

    function teamMint(address[] calldata addressList, uint256[] calldata quantity) external onlyOwner {
        require(addressList.length == quantity.length, "wrong length");
        for(uint i = 0 ; i < addressList.length ; i++) {
            teamMinted += quantity[i];
            require(teamMinted <= TEAM_SUPPLY, "EXCEED TEAM_SUPPLY");
            safeMint(addressList[i], quantity[i]);
        }
    }

    function safeMint(address to, uint256 amount) internal {
        require(_totalMinted() + amount <= TOTAL_SUPPLY, "EXCEED MAX_SUPPLY");
        _mint(to, amount);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        tokenBaseUri = _newBaseUri;
    }
}