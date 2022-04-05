# Burn

<p> The `burn` function from `useERC20` allows ... </p>

---

<br>

### burn

<p> The `burn` function takes ... </p>

```jsx
	const burn = async (amount: number) => {
		try {
			const burn = await proxyContract?.burn(amount);
			return burn.wait();
		} catch (err) {
			errors(err);
			throw err;
		}
	};
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