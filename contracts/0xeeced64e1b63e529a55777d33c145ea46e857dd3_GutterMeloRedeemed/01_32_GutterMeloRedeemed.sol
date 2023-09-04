//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./helpers/ERC721ABaseUpgradeable.sol";
import "./interfaces/IUnforged.sol";

contract GutterMeloRedeemed is ERC721ABaseUpgradeable {

    struct ForgeParams {
        address from;
        uint id;
        uint quantity;
        bytes32 nonce;
        uint timestamp;
    }

    struct ForgeMulParams {
        address from;
        uint[] ids;
        uint[] quantities;
        bytes32 nonce;
        uint timestamp;
    }

    bytes32 private constant FORGE_TYPEHASH = keccak256(
        "ForgeParams(address from,uint id,uint quantity,bytes32 nonce,uint timestamp)"
    );

    bytes32 private constant FORGE_MUL_TYPEHASH = keccak256(
        "ForgeMulParams(address from,uint[] ids,uint[] quantities,bytes32 nonce,uint timestamp)"
    );

    IUnforged private unforgedNft;
    mapping(address => bool) private paperAddresses;
    mapping(bytes32 => bool) private usedNonces;

    string private baseURI;
    string private contractBaseURI;

    bool public advancedFlowEnabled;

    event Forge(address from, uint id, uint quantity);
    event ForgeMultiple(address from, uint[] ids, uint[] quantities);

    function initialize() initializer public {
        __ERC721ABaseUpgradeable_init('GutterMeloRedeemed', 'GMELOX');

        _setDefaultRoyalty(0xB0d33Bd8F00695387f43D78Ed126d133D37C2d70, 750);
        _pause();
    }

    // for self-redeem
    function forge(uint id, uint quantity) external whenNotPaused {
        require(unforgedNft.balanceOf(_msgSender(), id) >= quantity, "Insufficient NFTs");

        unforgedNft.burn(_msgSender(), id, quantity);
        _mint(_msgSender(), quantity);

        emit Forge(_msgSender(), id, quantity);
    }

    function forgeMultiple(
        uint[] calldata ids,
        uint[] calldata quantities
    ) external whenNotPaused {
        require(ids.length == quantities.length, "Invalid parameters");
        for (uint i; i < ids.length; i++) {
            require(unforgedNft.balanceOf(_msgSender(), ids[i]) >= quantities[i], "Insufficient NFTs");

            unforgedNft.burn(_msgSender(), ids[i], quantities[i]);
            _mint(_msgSender(), quantities[i]);
        }

        emit ForgeMultiple(_msgSender(), ids, quantities);
    }
    
    function forgeAdvanced(ForgeParams calldata params, bytes calldata signature) external whenNotPaused {
        require(advancedFlowEnabled, "Flow is not enabled");
        require(params.from == _msgSender() || paperAddresses[_msgSender()], "Not allowed");
        require(unforgedNft.balanceOf(params.from, params.id) >= params.quantity, "Insufficient NFTs");

        require(params.timestamp + 86400 >= block.timestamp, "Timestamp too old");
        require(!usedNonces[params.nonce], "Nonce used");
        require(_validateSigner(params, signature), "Signer invalid");

        unforgedNft.burn(params.from, params.id, params.quantity);
        _mint(params.from, params.quantity);

        usedNonces[params.nonce] = true;

        emit Forge(params.from, params.id, params.quantity);
    }

    function forgeMultipleAdvanced(
        ForgeMulParams calldata params,
        bytes calldata signature
    ) external whenNotPaused {
        require(advancedFlowEnabled, "Flow is not enabled");
        require(params.from == _msgSender() || paperAddresses[_msgSender()], "Not allowed");

        require(params.timestamp + 86400 >= block.timestamp, "Timestamp too old");
        require(!usedNonces[params.nonce], "Nonce used");
        require(_validateSignerMul(params, signature), "Signer invalid");

        require(params.ids.length == params.quantities.length, "Invalid parameters");
        for (uint i; i < params.ids.length; i++) {
            require(unforgedNft.balanceOf(params.from, params.ids[i]) >= params.quantities[i], "Insufficient NFTs");

            unforgedNft.burn(params.from, params.ids[i], params.quantities[i]);
            _mint(params.from, params.quantities[i]);
        }

        usedNonces[params.nonce] = true;

        emit ForgeMultiple(params.from, params.ids, params.quantities);
    }

    function _validateSigner(ForgeParams calldata params, bytes calldata signature) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                FORGE_TYPEHASH,
                params.from,
                params.id,
                params.quantity,
                params.nonce,
                params.timestamp
            )
        );
        address recoveredSignerAddress = ECDSA.recover(
            ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash), signature
        );

        return recoveredSignerAddress == params.from;        
    }

    function _validateSignerMul(ForgeMulParams calldata params, bytes calldata signature) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                FORGE_MUL_TYPEHASH,
                params.from,
                keccak256(abi.encodePacked(params.ids)),
                keccak256(abi.encodePacked(params.quantities)),
                params.nonce,
                params.timestamp
            )
        );
        address recoveredSignerAddress = ECDSA.recover(
            ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash), signature
        );

        return recoveredSignerAddress == params.from;        
    }

    // administrative functions
    function setUnforgedNFT(address _unforged) external onlyOwner {
        unforgedNft = IUnforged(_unforged);
    }

    function setPaperAddress(address _paperAddress, bool _isPaperAddress) external onlyOwner {
        paperAddresses[_paperAddress] = _isPaperAddress;
    }

    function setPaperAddresses(address[] calldata _paperAddresses, bool _isPaperAddress) external onlyOwner {
        for (uint i; i < _paperAddresses.length; i++) {
            paperAddresses[_paperAddresses[i]] = _isPaperAddress;
        }
    }

    function setAdvancedFlowEnabled(bool _enabled) external onlyOwner {
        advancedFlowEnabled = _enabled;
    }

    // NFT functions
    function tokenURI(uint tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
		return contractBaseURI;
	}

    function setBaseURI(string memory newBaseURI) external onlyOwner {
		baseURI = newBaseURI;
	}

	function setContractURI(string memory newContractURI) external onlyOwner {
		contractBaseURI = newContractURI;
	}

}