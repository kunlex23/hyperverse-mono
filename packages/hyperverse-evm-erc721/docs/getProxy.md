# Get Proxy

<p> The `getProxy` function from `useERC721` ... </p>

---

<br>

### getProxy

<p> The `getProxy` function takes in a ... </p>

```jsx
	const getProxy = async (account: string | null) => {
		try {
			console.log("getProxy:", account);
			const proxyAccount = await factoryContract.getProxy(account);
			return proxyAccount;
		} catch (err) {
			errors(err);
			throw err;
		}
	}
```

### Stories

```jsx

```

### Main UI Component

```jsx

```

### Args

```jsx

```

For more information about our modules please visit: [**Hyperverse Docs**](docs.hyperverse.dev)