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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IGPC.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GPC2 is ERC721A, Ownable, ReentrancyGuard {
    bytes32 public merkleRoot; // root to be generated after full whitelist addresses are done;
    IGPC GPC_CHEMISTRY_CONTRACT =
        IGPC(0x495f947276749Ce646f68AC8c248420045cb7b5e); //OS OpenStore Smart Contract Address

    string public contractURI =
        "https://mint.goldpandaclub.com/contractmetadata.json"; //link to metadata.json for contract info
    uint96 public royaltyFeesInBips = 999; //royalty fee in bases points (100 = 1% 999 = 9.99%)
    address public royaltyReceiver; //address to deposit royalties
    string public hiddenMetadataUri =
        "ipfs://bafkreidjldxj35sic625rw4mnbl7pthesvbq4jrb5mchla73mfbmpmrdbm"; //default hidden metadata
    string public baseURI; //the reveal URI to be set a later time

    string public mutantURI = "";
    string public superMutantURI = "";
    string public megaMutantURI = "";

    uint256 public cost = 0.079 ether; //mint price
    uint256 public currentMaxSupply = 865; //project supply
    mapping(uint256 => uint256) public currentMutantsMaxSupply;
    mapping(uint256 => uint256) public mutantsSupply;
    mapping(string => uint256) public mutantsMinted;
    uint256 public mutantsCount;

    bool public mintEnabled = false; //disable and enable the mint
    bool public mutantMintEnabled = false; //disable and enable the mint
    bool public revealed = false; //disable and enable reveal after baseURI is set

    mapping(address => uint256) public _claimed; //mapping of addresses that claimed and how much they have claimed

    constructor() ERC721A("Gold Panda Club 2", "GPC2") {
        royaltyReceiver = address(0x91153D6B02774f8Ae7faAd0ce0BDbA9Cfc14398B);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        //check that there is enough supply left
        require(
            totalSupply() - mutantsCount + _mintAmount <= currentMaxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        //check the address has enough mula
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }
    modifier mintEnabledCompliance() {
        //check that we enabled mint
        require(mintEnabled, "The mint sale is not enabled!");
        _;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        mintEnabledCompliance
        mintCompliance(quantity)
        mintPriceCompliance(quantity)
        nonReentrant
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Not on the allowlist"
        ); //check that address is indeed on allowlist. No hacky hacky

        _claimed[msg.sender] = _claimed[msg.sender] + quantity; //add how many claimed in this transaction. maybe only claimed a poriton of max

        _safeMint(msg.sender, quantity, 0); //bbbrrrrrr
    }

    function mutantMint(uint256 _osTokenId, uint256 quantity)
        external
        payable
        nonReentrant
    {
        require(mutantMintEnabled, "Mutant Mint Not Enabled");
        require(
            GPC_CHEMISTRY_CONTRACT.balanceOf(msg.sender, _osTokenId) > 1,
            "No Serums found"
        );
        require(
            (quantity +
                mutantsMinted[string(abi.encode(msg.sender, _osTokenId))]) <=
                GPC_CHEMISTRY_CONTRACT.balanceOf(msg.sender, _osTokenId),
            "Quantity is greater than serum count"
        );

        require(
            currentMutantsMaxSupply[_osTokenId] != 0,
            "Incorrect serum passed in"
        );

        require(
            mutantsSupply[_osTokenId] + quantity <=
                currentMutantsMaxSupply[_osTokenId],
            "MAX MUTANTS MINTED"
        );

        GPC_CHEMISTRY_CONTRACT.burn(msg.sender, _osTokenId, quantity);

        uint256 mutantAddIndex = 0;
        if (currentMutantsMaxSupply[_osTokenId] == 25) {
            mutantAddIndex = 100;
        } else if (currentMutantsMaxSupply[_osTokenId] == 10) {
            mutantAddIndex = 125;
        }

        _safeMint(
            msg.sender,
            quantity,
            ((currentMaxSupply + _startTokenId()) +
                mutantAddIndex +
                mutantsSupply[_osTokenId])
        );

        mutantsCount = mutantsCount + quantity;
        mutantsMinted[string(abi.encode(msg.sender, _osTokenId))] = quantity;
        mutantsSupply[_osTokenId] = mutantsSupply[_osTokenId] + quantity;
    }

    function getSerumBalance(uint256 _osTokenId, address _address)
        public
        view
        virtual
        returns (uint256)
    {
        return GPC_CHEMISTRY_CONTRACT.balanceOf(_address, _osTokenId);
    }

    function totalSupply()
        public
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        unchecked {
            return super.totalSupply() + mutantsCount;
        }
    }

    function _exists(uint256 tokenId)
        internal
        view
        override(ERC721A)
        returns (bool)
    {
        bool exists = super._exists(tokenId);
        if (exists) {
            return true;
        }
        return mutantsIndexes[tokenId];
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

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        if (bytes(currentBaseURI).length == 0) {
            return "";
        }

        if (_tokenId > 500 && _tokenId <= 1365) {
            return
                string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }

        if (_tokenId > 1365 && _tokenId <= 1465) {
            return
                string(
                    abi.encodePacked(
                        mutantURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }

        if (_tokenId > 1465 && _tokenId <= 1490) {
            return
                string(
                    abi.encodePacked(
                        superMutantURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }
        if (_tokenId > 1490 && _tokenId <= 1500) {
            return
                string(
                    abi.encodePacked(
                        megaMutantURI,
                        Strings.toString(_tokenId),
                        ".json"
                    )
                );
        }

        return "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 501;
    }

    function setCurrentMaxSupply(uint256 _supply) public onlyOwner {
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

    function setMutantMintEnable(bool _mutantMintEnabled) public onlyOwner {
        mutantMintEnabled = _mutantMintEnabled;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMutantMetadataUri(string memory _mutantURI) public onlyOwner {
        mutantURI = _mutantURI;
    }

    function setSuperMutantMetadataUri(string memory _superMutantURI)
        public
        onlyOwner
    {
        superMutantURI = _superMutantURI;
    }

    function setMegaMutantMetadataUri(string memory _megaMutantURI)
        public
        onlyOwner
    {
        megaMutantURI = _megaMutantURI;
    }

    function setCurrentMutantsMaxSupply(
        uint256 _mutantsSupply,
        uint256 _osTokenId
    ) public onlyOwner {
        currentMutantsMaxSupply[_osTokenId] = _mutantsSupply;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setOSContract(address _address) public onlyOwner {
        GPC_CHEMISTRY_CONTRACT = IGPC(_address);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function reserve(uint32 _count)
        public
        virtual
        onlyOwner
        mintCompliance(_count)
    {
        _safeMint(msg.sender, _count, 0); //bbbrrrrrr
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
}