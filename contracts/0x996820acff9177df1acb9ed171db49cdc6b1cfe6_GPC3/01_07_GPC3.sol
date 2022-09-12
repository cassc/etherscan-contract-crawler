//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMFVVVVVVVVFIMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMVV**************:***VFMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMIMMMIV*:*V**VVVVVVVVVVVVVVVV****VMMMMIMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMV***:*:*:***VVVFFFFVFVFVVVFVFVFVVVV*::*******VMMMMMMMMMMMMMM
MMMMMMMMMMMMMF**VVVV***VVVVVVVFVFFVFFFFVVFFFVFVFIVVVV***VFV*:*IMMMMMMMMMMMM
MMMMMMMMMMMMV:VVVV****VVVFVVVFVVVFVVVVVVVVVVVVVFVFFVVVV**VVFV*:FMMMMMMMMMMM
MMMMMMMMMMMM:*VVV***VVVVFFFVVIFFFVVVVVVVVVVVVVVVVVVVVFFVV**FIV:*MMMMMMMMMMM
MMMMMMMMMMMM:*FV***V*VFVVVVVVVVVFVVVVVVVVVVVVVVVVVVVVFVFVV**VI**MMMMMMMMMMM
MMMMMMMMMMMMV:****VVVVVVVVVVVVVVVFVVVVVVFFVVFFVVVVVFFVVVMFV***:FMMMMMMMMMMM
MMMMMMMMMMMMM****VVVVVVVVVVV*VVVVVVVVVFVVVVFVVVVVVVVVVVVFVFV*:*MMMMMMMMMMMM
MMMMMMMMMMMM*:**VVVVVV**VVV*VVVVVVVV***V**VVVVVVVVVVVVFFVFFV**:VMMMMMMMMMMM
MMMMMMMMMMMV:**VVVVVVVV*VVV*V**************VVVVVVVVFVVVFVVVVVV*:FMMMMMMMMMM
MMMMMMMMMMM****VV*VVVVVVVVVV********:******VVVVVFVVVVVVVVVFFVV*:*MMMMMMMMMM
MMMMMMMMMMI:**VVVVVVVVVVV*V**V***********V*VVVVVFVVFVVVVFVVVVV**:MMMMMMMMMM
MMMMMMMMMMV:**VVVVVVVVVVVV*VVVVVVVVVVVVV*VVVVVVVVVFVFVVVVFFVVV**:MMMMMMMMMM
MMMMMMMMMMF:*VV*VVVVVVVVVVVV*VV*VVVVVVVVVVFVVVVVVVFVVVVVVVFVVV**:MMMMMMMMMM
MMMMMMMMMMM**VVVV*VVVVV*VV**VVVVVVVVVVVVVVVFVVVVVFFVIIVVVVVVVVV**MMMMMMMMMM
MMMMMMMMMMMV*VVVVVVVVVVVVVVVV*VVVVVFFVVVVVVFFVVFVVVFIIVIVVVVVV*:VMMMMMMMMMM
MMMMMMMMMMMM**VVVVVV*VVVVVVVVVVVVFVVVFFFIFVIVFVIVVVVMVVFVVVV****MMMMMMMMMMM
MMMMMMMMMMMMI**VVVVVVVVV*VVVVVVVVVVFFVVIMIIVIFFVIVVFIFVVVVVV***IMMMMMMMMMMM
MMMMMMMMMMMMMIVVVVVVVVV*V*VVVVVVVVVVVVVFIIIVVFVVIFFFVVFVVVV***MMMMMMMMMMMMM
MMMMMMMMMMMMMMMFVVVV*VVVVVVVVVFVVVVVVVVVVVVVFVVVVVVVVVVVV***FMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMFVVVVVVVVVVVVVVVVVVVVIVVVVVVVVFVVVVVVVV*VFMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMIVVIMIIFVFVIIFFIIIFIIFIFIVFFFIFMMMM*VIMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMFVVVVVV*VMIFIMMNMN$NNNNNMMMMMMMMMMNMIIMMMV*VVVVVVIMMMMMMMMMMMM
MMMMMMMMMMMF**VFIMMMVVVVVVFVFIIMMMMMMIIMMMMMIIFVFFVIMMVV$$NNMV**FMMMMMMMMMM
MMMMMMMMMI***VVFVVFMV*VVVVVVVVVVFFVVVFFFFFFFFFVVVFVIIMVV$IVVIIFV*VMMMMMMMMM
MMMMMMMMF**VVVVVV**IV*VVVVVVVVFIFIMMMNMMIMFFFFVFVVFFVVVIMVVVVVVV***IMMMMMMM
MMMMMMMV:**VV**VVVVIV*VVVVVVVIFIFIMIIIIIFIIFFIVVVVFVFV*VMIFV*VVVVV*:FMMMMMM
MMMMMMI:*VVVVVVVVIIF****VVVVVFFFVVVVVVVVVVVVVVFFVVVVVV**IIIFVVVVVVV**MMMMMM
MMMMMM*:*VV**VVVVVV****VVVVVVVVVVV**V**VVVVVVVVVVVVVVV**VVVFVVVVFVV***MMMMM
MMMMM*:*VV***VVVFFV****VVVV**VV************V**VVVVVVVV***VFFFVV*VVVV*:VMMMM
MMMMV:**V**VV*VFFV::**VVVV*V**V**********:*******VVV*VV***VVVVVV*VVVV*:IMMM
MMMM*:*VV*V**VVVV*:**VV*******V**V************VVVVVVV*V**:*VVVV**VVVV*:VMMM
MMMI:**VV****VVVV::*VVV**V*****VV*VV*V*VV**V*VVVVVV*VV***::VVVV**VVVV*:*MMM
MMMV.*VVV****VVVV*:**V*V*VVV*VVVVVFVVVVVVVVVVVVVV*VVVV****:VVVVV*VVVVV*:MMM
MMMV:**V*V*VVVVV*:****VVVVVVVVVVV*FVVVVVVV*VVVVVV*V**V****:*VVVV**VVV**:IMM
MMM*:**V****VVFVV**V*VVV*V*VVVVVVVVFVVVVVVV*VVVV*VV***V***:*FIV**VVVVV*:VMM
MMMV:***VVVVVVVV****VFVVV*VV*VIVIFVVMFVFVVVVVVV*****V*****:*VVVVVVVVV**:VMM
MMMM***VV*VVVFIIV***VVVVVVVVVVVVVVMVVFVIIVVVVVF*VVVVV*****:VIFVFIVVVV**:MMM
MMMM***VVVVVVFIMV****VVVVFFVVVVVVIIFVVFMVVFVVVV*VV*V**V***:VMMIIVF*VV*:*MMM
MMMMV*:*VVVVVVIMV****VVVVVVVFVVV*IMVVVVVVMVVVVVVVFV**V****:VMFVVVFVVV::VMMM
MMMMMV**VVVVVVMFV***VVVVVVVFVFIVVVVVVIFVVMV*VVVVVVFVVVVV*::*VFVVFFFV*:*MMMM
MMMMMMV***VVVVVVVV:*VVVVVVMIVIVIFIIVVIVVVVFVVVVFVVVFVV***:***VVVVV**:*MMMMM
MMMMMMMMFVVVVVVIMM*VVV*FVVVVVVVVVFVFIIIV*VV*****V*********IIVV*****VFMIMMMM
MMMMMMMMMMMMMMMMMF*FMMMIIMMMNMMFVVVVVMVVVVV*VIIIFVVVVVFMV*IIIIIIIIIIIIIIMMM
MMMMMMMMMMMMMMMMMV**VVVVVFVFVFIIVVVVFVVV*V**VVVV****V*VV*:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV*VFV*VVVVVVFVF*VF*VFVVVV**VV***V**V**V*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV**VVV*VVVVVVVVV**V*VVVV**V*************:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*VV***V***VV*VMVVVV*V*VVV*****V****VV*.VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*V*******V****VFFVMIVFVVV*****VVV***V*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*V*****VV*VVV*VVI*VV*V*VVVV****VV*VVV*:FMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*****VVVV*V***VVV*VV*V*VVVVV*V*V******:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:**V*VVVVV**VV*VVF*VV****V******VV**V**:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMV:*VV*VVFVVVVV**VVI*V****VV*V*****VV****:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM*:*V****VVVVV*VV**V*V**V*******V******V*:VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM******VVFVVVFFV*****VV**:**VVV*VVVVV**:::VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM*:**VVFIFV*VVVVVVV*:*V::*VVVVVV*VVVVVV*:.*MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM**VVVVFVVFVVVVVVVV*:**:*VVVV*VVVVVV*****:*MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMI:*VVVVVV******VVVV*:**:**VV*******VV**VV::MMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMVVVVVFVVFVFVVVVVVVV*VV**V*VVVVVVVVVVVVVV*VMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMIVVVFIIIMIIFFIIMMIMMMMMIIMMIMMIMIMMMMMMMMMMMMMMMMMMMMMM
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GPC3 is ERC721A, Ownable, ReentrancyGuard {
    string public contractURI =
        "https://giftshop.goldpandaclub.com/contractmetadata.json"; //link to metadata.json for contract info
    uint96 public royaltyFeesInBips = 999; //royalty fee in bases points (100 = 1% 999 = 9.99%)
    address public royaltyReceiver; //address to deposit royalties
    string public baseURI =
        "https://giftshop.goldpandaclub.com/api/panda3/metadata/";

    mapping(uint256 => uint256) public cost; //mint price
    uint256 public currentMaxSupply = 0; //project supply

    bool public mintEnabled = true; //disable and enable the mint

    uint256 public mintedCount;
    mapping(uint256 => uint256) public mintedTokens;
    address mmContract;

    constructor() ERC721A("Gold Panda Club 3", "GPC3") {
        royaltyReceiver = address(0x91153D6B02774f8Ae7faAd0ce0BDbA9Cfc14398B);
    }

    function setMMContract(address _contract) external onlyOwner {
        mmContract = _contract;
    }

    modifier mintCompliance(uint256[] memory token_ids) {
        //check that there is enough supply left.
        for (uint256 i = 0; i < token_ids.length; i++) {
            require(
                token_ids[i] <= currentMaxSupply,
                "Cannot mint tokens greater than max supply"
            );
        }
        _;
    }

    modifier mintEnabledCompliance() {
        //check that we enabled mint
        require(mintEnabled, "The mint sale is not enabled!");
        _;
    }

    function getMintTime(uint256 _tokenId) public view returns (uint256) {
        return mintedTokens[_tokenId];
    }

    function getCost(uint256 token_id) public view returns (uint256) {
        return cost[token_id];
    }

    function mint(uint256[] memory token_ids, address sender)
        external
        mintEnabledCompliance
        mintCompliance(token_ids)
        nonReentrant
    {
        require(msg.sender == mmContract, "Please use the website to mint");

        for (uint256 i = 0; i < token_ids.length; i++) {
            uint256 idToMint = (1500 + token_ids[i]);
            _safeMint(sender, 1, idToMint); //bbbrrrrrr
            mintedTokens[idToMint] = block.timestamp;
        }

        mintedCount += token_ids.length;
    }

    function _exists(uint256 tokenId)
        internal
        view
        override(ERC721A)
        returns (bool)
    {
        return mintedTokens[tokenId] == 0 ? false : true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        //override to return hidden URI instead until reveal
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length == 0) {
            return "";
        }
        return
            string(
                abi.encodePacked(currentBaseURI, Strings.toString(_tokenId))
            );
    }

    function increasePandaSupply(uint256 _cost, uint256 increaseBy)
        public
        onlyOwner
    {
        uint256 curId = (currentMaxSupply + 1501);

        for (uint256 i = curId; i < curId + increaseBy; i++) {
            cost[i] = _cost;
        }

        setCurrentMaxSupply(currentMaxSupply + increaseBy);
    }

    function setCurrentMaxSupply(uint256 _supply) private onlyOwner {
        require(
            _supply >= totalSupply(),
            "Cannot set supply to lower than current total supply"
        );
        currentMaxSupply = _supply;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setRoyaltyReceiver(address _receiver) public onlyOwner {
        royaltyReceiver = _receiver;
    }

    function setRoyaltyBips(uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function setMintEnable(bool _enableMint) public onlyOwner {
        mintEnabled = _enableMint;
    }

    function setCost(uint256 token_id, uint256 _cost) public onlyOwner {
        cost[token_id] = _cost;
    }

    function setCostBatch(uint256[] memory token_ids, uint256[] memory _costs)
        public
        onlyOwner
    {
        require(
            _costs.length == token_ids.length,
            "Arrays length have to match"
        );
        for (uint256 i = 0; i < _costs.length; i++) {
            cost[token_ids[i]] = _costs[i];
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        unchecked {
            return mintedCount;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, calculateRoyalty(_salePrice));
    }

    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    function withdrawEth() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}