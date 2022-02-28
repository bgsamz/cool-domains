// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import { Base64 } from "./libraries/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string constant SVG_PREFIX = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800" width="800" height="800" style="background-color:#3091ff"><defs><pattern id="a" width="40" height="40" patternUnits="userSpaceOnUse" patternTransform="rotate(35) scale(3)"><path d="M7.93 25.486v-6l8.83 5.1v6l-8.83-5.1Z" fill="#ffb05f"/><path d="M16.76 30.587v-6l12.08-1.86.003 6-12.083 1.86Z" fill="#c55000"/><path d="M32.07 21.747v-6l-3.23 6.98v6l3.23-6.98Z" fill="#ffb05f"/><path d="m11.161 12.516 12.074-1.867 8.839 5.102-3.235 6.97-12.074 1.868-8.84-5.102 3.236-6.97Z" fill="#ff7f30"/></pattern><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="800" width="800"><feDropShadow dx="2" dy="3" stdDeviation="10" flood-opacity="225" width="200%" height="200%"/></filter></defs><path fill="url(#a)" filter="url(#b)" d="M0 0h800v800H0z" transform="scale(1.5)"/><path filter="url(#b)" d="M218.589 128.847a13.147 13.147 0 0 0-13.182 0l-30.243 18.096-20.55 11.802-30.243 18.096a13.147 13.147 0 0 1-13.182 0L87.15 162.678a13.56 13.56 0 0 1-4.767-4.848 13.623 13.623 0 0 1-1.824-6.561v-27.93a12.813 12.813 0 0 1 1.716-6.624 12.75 12.75 0 0 1 4.875-4.785l23.652-13.77a13.147 13.147 0 0 1 13.182 0l23.652 13.77a13.56 13.56 0 0 1 4.767 4.848 13.623 13.623 0 0 1 1.824 6.561v18.096l20.55-12.195v-18.096a12.813 12.813 0 0 0-1.716-6.624 12.75 12.75 0 0 0-4.875-4.785L124.368 73.77a13.147 13.147 0 0 0-13.182 0L66.594 99.735a12.75 12.75 0 0 0-4.875 4.785 12.82 12.82 0 0 0-1.716 6.624v52.323a12.813 12.813 0 0 0 1.716 6.624 12.75 12.75 0 0 0 4.875 4.785l44.592 25.965a13.147 13.147 0 0 0 13.182 0l30.243-17.703 20.55-12.195 30.243-17.703a13.147 13.147 0 0 1 13.182 0l23.652 13.77a13.56 13.56 0 0 1 4.767 4.848 13.623 13.623 0 0 1 1.824 6.561v27.933a12.813 12.813 0 0 1-1.716 6.624 12.75 12.75 0 0 1-4.875 4.785l-23.652 14.163a13.147 13.147 0 0 1-13.182 0l-23.652-13.77a13.56 13.56 0 0 1-4.767-4.848 13.59 13.59 0 0 1-1.824-6.561v-18.096l-20.55 12.195v18.096a12.813 12.813 0 0 0 1.716 6.624 12.75 12.75 0 0 0 4.875 4.785l44.592 25.965a13.147 13.147 0 0 0 13.182 0l44.592-25.965c1.971-1.182 3.612-2.85 4.767-4.848s1.782-4.254 1.827-6.561v-52.326a12.813 12.813 0 0 0-1.716-6.624 12.75 12.75 0 0 0-4.875-4.785l-44.979-26.358z" fill="#fff"/><text x="96" y="685" font-size="80" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
  string constant SVG_SUFFIX = '</text></svg>';

  uint constant MAX_LENGTH = 13;

  // Owner of the contract that can withdraw funds
  address payable public owner;
  // Top-level domain that users will register under
  string public tld;

  // Mapping of domain -> owning address
  mapping(string => address) public domains;
  // Mapping of domain -> actual record
  mapping(string => string) public records;
  mapping (uint => string) public names;

  // Errors
  error Unauthorized();
  error AlreadyRegistered();
  error InvalidName(string name);

  constructor(string memory _tld) ERC721("Music Name Service", "MUS") payable {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed!", _tld);
  }

  // Return the price of the domain based on the length
  function price(string calldata name) public pure returns (uint) {
    uint len = StringUtils.strlen(name);
    require(len > 1, "Domain length must be greater than 0!");

    if (len == 3) {
      return 5 * 10**17;
    } else if (len == 4) {
      return 3 * 10**17;
    } else {
      return 1 * 10**17;
    }
  }

  function valid(string calldata name) public pure returns(bool) {
    return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
  }

  function register(string calldata name) public payable {
    if (domains[name] != address(0)) revert AlreadyRegistered();
    if (!valid(name)) revert InvalidName(name);

    uint _price = price(name);
    // Make sure there was enough paid in the transaction
    require(msg.value >= _price, "Not enough Matic paid!");

    string memory _name = string(abi.encodePacked(name, ".", tld));
    string memory finalSvg = string(abi.encodePacked(SVG_PREFIX, _name, SVG_SUFFIX));
    uint newRecordId = _tokenIds.current();
    uint length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    console.log("Registering %s on the contract with tokenId %d", _name, newRecordId);

    // Create the metadata for our NFT
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            _name,
            '", "description": "A domain on the .', tld,
            ' name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    console.log("\n--------------------------------------------------------");
    console.log("Final tokenURI", finalTokenUri);
    console.log("--------------------------------------------------------\n");

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;
    names[newRecordId] = name;

    _tokenIds.increment();
  }

  function getAddress(string calldata name) public view returns (address) {
    return domains[name];
  }

  function setRecord(string calldata name, string calldata record) public {
    if (msg.sender != domains[name]) revert Unauthorized();
    records[name] = record;
  }

  function getRecord(string calldata name) public view returns (string memory) {
    return records[name];
  }

  function getAllNames() public view returns (string[] memory) {
    console.log("Getting all names from contract");
    string[] memory allNames = new string[](_tokenIds.current());
    for (uint i = 0; i < _tokenIds.current(); i++) {
      allNames[i] = names[i];
      console.log("Name for token %d is %s", i, allNames[i]);

    }

    return allNames;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function withdraw() public onlyOwner {
    uint amount = address(this).balance;

	(bool success, ) = msg.sender.call{value: amount}("");
	require(success, "Failed to withdraw Matic");
  }
}