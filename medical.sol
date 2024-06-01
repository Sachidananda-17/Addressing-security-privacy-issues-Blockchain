// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PharmaDataRegistry {
    address public owner;

    enum UserRole { Manufacturer, Distributor, Retailer }

    struct Medicine {
        address manufacturer;
        string name;
        string batchNumber;
        uint256 manufacturingDate;
        uint256 expiryDate;
        uint256 price;
        uint256 quantity;
        string description;
        string composition;
        string usage;
    }

    mapping(address => UserRole) private userRoles;
    mapping(address => Medicine[]) private medicineRecords;

    event MedicineManufactured(address indexed manufacturer, string batchNumber);
    event MedicineSold(address indexed seller, address indexed buyer, string batchNumber, uint256 quantity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyManufacturer() {
        require(userRoles[msg.sender] == UserRole.Manufacturer, "Only manufacturers can call this function");
        _;
    }

    modifier onlyDistributorOrRetailer() {
        require(
            userRoles[msg.sender] == UserRole.Distributor || userRoles[msg.sender] == UserRole.Retailer,
            "Only distributors and retailers can call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addUser(address user, UserRole role) external onlyOwner {
        userRoles[user] = role;
    }

    function manufactureMedicine(
        string memory name,
        string memory batchNumber,
        uint256 manufacturingDate,
        uint256 expiryDate,
        uint256 price,
        uint256 quantity,
        string memory description,
        string memory composition,
        string memory usage
    ) external onlyManufacturer {
        Medicine memory newMedicine = Medicine({
            manufacturer: msg.sender,
            name: name,
            batchNumber: batchNumber,
            manufacturingDate: manufacturingDate,
            expiryDate: expiryDate,
            price: price,
            quantity: quantity,
            description: description,
            composition: composition,
            usage: usage
        });

        medicineRecords[msg.sender].push(newMedicine);

        emit MedicineManufactured(msg.sender, batchNumber);
    }

    function sellMedicine(address buyer, string memory batchNumber, uint256 quantity) external onlyDistributorOrRetailer {
        Medicine[] storage medicines = medicineRecords[msg.sender];
        int256 index = findMedicineIndexByBatchNumber(medicines, batchNumber);

        require(index != -1, "Medicine not found");
        require(uint256(index) < medicines.length, "Invalid index");
        require(medicines[uint256(index)].quantity >= quantity, "Insufficient quantity");

        medicines[uint256(index)].quantity -= quantity;

        medicineRecords[buyer].push(Medicine({
            manufacturer: medicines[uint256(index)].manufacturer,
            name: medicines[uint256(index)].name,
            batchNumber: batchNumber,
            manufacturingDate: medicines[uint256(index)].manufacturingDate,
            expiryDate: medicines[uint256(index)].expiryDate,
            price: medicines[uint256(index)].price,
            quantity: quantity,
            description: medicines[uint256(index)].description,
            composition: medicines[uint256(index)].composition,
            usage: medicines[uint256(index)].usage
        }));

        emit MedicineSold(msg.sender, buyer, batchNumber, quantity);
    }

    function getUserRole(address user) external view returns (UserRole) {
        return userRoles[user];
    }

    function getUserMedicineCount(address user) external view returns (uint256) {
        return medicineRecords[user].length;
    }

    function getUserMedicine(address user, uint256 index) external view returns (
        address manufacturer,
        string memory name,
        string memory batchNumber,
        uint256 manufacturingDate,
        uint256 expiryDate,
        uint256 price,
        uint256 quantity,
        string memory description,
        string memory composition,
        string memory usage
    ) {
        require(index < medicineRecords[user].length, "Invalid index");
        Medicine memory medicine = medicineRecords[user][index];
        return (
            medicine.manufacturer,
            medicine.name,
            medicine.batchNumber,
            medicine.manufacturingDate,
            medicine.expiryDate,
            medicine.price,
            medicine.quantity,
            medicine.description,
            medicine.composition,
            medicine.usage
        );
    }

    function findMedicineIndexByBatchNumber(Medicine[] storage medicines, string memory batchNumber) internal view returns (int256) {
        for (int256 i = 0; i < int256(medicines.length); i++) {
            if (keccak256(bytes(medicines[uint256(i)].batchNumber)) == keccak256(bytes(batchNumber))) {
                return i;
            }
        }
        return -1;
    }
}
